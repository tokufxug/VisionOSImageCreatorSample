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
    @State private var generatedImages: [Image] = []
    @State private var isLoading = false
    @State private var inputText: String = "A cat wearing mittens"
    @State private var generatedText: String = ""
    @State private var imageLimit: Int = 1
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
            
            HStack {
                TextField("Enter description (e.g. A cat wearing mittens)", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 400)
                    .padding()
                
                Picker("Image Limit", selection: $imageLimit) {
                    ForEach(limitOptions, id: \..self) { limit in
                        Text("\(limit)").tag(limit)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
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
        .padding()
    }
    
    @MainActor
    func generateImage() async {
        isLoading = true
        generatedImages.removeAll()
        generatedText = ""
        
        do {
            let creator = try await ImageCreator()
            guard let style = creator.availableStyles.first else { return }
            
            let images = creator.images(
                for: [.text(inputText)],
                    style: style,
                    limit: imageLimit)
            generatedText = inputText
            for try await image in images {
                let uiImage = UIImage(cgImage: image.cgImage)
                generatedImages.append(Image(uiImage: uiImage))
            }
        } catch {
            generatedText = "Failed to generate image: \(error) : \(inputText)"
        }
        isLoading = false
        inputText = ""
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
