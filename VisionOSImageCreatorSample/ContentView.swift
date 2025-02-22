//
//  ContentView.swift
//  VisionOSImageCreatorSample
//
//  Created by Sadao Tokuyama on 2/22/25.
//

import SwiftUI
import ImagePlayground

struct ContentView: View {
    
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground
    @State private var creator: ImageCreator?
    @State private var generatedImages: [Image] = []
    @State private var isLoading = false
    @State private var inputText: String = "A cat wearing mittens"
    @State private var generatedText: String = ""
    @State private var imageLimit: Int = 1
    @State private var selectedStyleId: String = ""
    let limitOptions = Array(1...4)
    
    var body: some View {
        VStack {
            if !generatedImages.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(generatedImages.indices, id: \..self) { index in
                            generatedImages[index]
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                            }
                        }
                }
            } else {
                if ImagePlaygroundViewController.isAvailable && supportsImagePlayground {
                    Text("No image generated")
                        .foregroundColor(.gray)
                } else {
                    Text("ImagePlayground unavailable")
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 16) {
                TextField("Enter description (e.g. A cat wearing mittens)", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 400)
                Picker("Image Limit", selection: $imageLimit) {
                    ForEach(limitOptions, id: \..self) { limit in
                        Text("\(limit)").tag(limit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                if let creator = creator, !creator.availableStyles.isEmpty {
                    Picker("Select Style", selection: $selectedStyleId) {
                        ForEach(creator.availableStyles, id: \.self) { style in
                            Text(style.id).tag(style.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                Button("Clear") {
                    if let firstStyle = creator?.availableStyles.first {
                        selectedStyleId = firstStyle.id
                    }
                    inputText = ""
                    imageLimit = 1
                }
            }
            
            Button(action: {
                Task {
                    await generateImage()
                }
            }) {
                Text("Generate Image")
                    .padding()
            }
            .disabled(!ImagePlaygroundViewController.isAvailable || !supportsImagePlayground || inputText.isEmpty || isLoading)
            
            if !generatedText.isEmpty {
                Text(generatedText)
            }
        }
        .onAppear {
            if ImagePlaygroundViewController.isAvailable && supportsImagePlayground {
                Task {
                    do {
                        creator = try await ImageCreator()
                        if let firstStyle = creator?.availableStyles.first {
                            selectedStyleId = firstStyle.id
                        }
                    } catch {
                        // Handle error if needed
                    }
                }
            }
        }
        .padding()
    }
    
    @MainActor
    func generateImage() async {
        isLoading = true
        generatedText = ""
        do {
            guard let creator = creator else { return }
            guard let style = creator.availableStyles.first(where: { $0.id == selectedStyleId }) else {
                    generatedText = "Style not found"
                    isLoading = false
                    return
            }
            let images = creator.images(
                for: [.text(inputText)],
                    style: style,
                    limit: imageLimit)
            generatedText = "\(selectedStyleId) : \(inputText)"
            for try await image in images {
                let uiImage = UIImage(cgImage: image.cgImage)
                generatedImages.insert(Image(uiImage: uiImage), at: 0)
            }
        } catch {
            generatedText = "Failed to generate image: \(error) : \(selectedStyleId) : \(inputText)"
        }
        isLoading = false
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
