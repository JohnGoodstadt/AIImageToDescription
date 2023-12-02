//
//  ContentView.swift
//  AIImageToDescription
//
//  Created by John goodstadt on 02/12/2023.
//

import SwiftUI
import MLImage
import MLKit

struct ContentView: View {
	
	@State var selectedRow: String = ""
	@State private var showMessageToast = false
	@State private var imageDescription = "Description will go here"
	@State private var confidence   = "0.7"
	@State private var mainImage = UIImage(named: "previewImage")
	
	@State var confidencePicked = 0.7
	private let photoURL = URL(string: "https://picsum.photos/512.jpg")
	
	var body: some View {
		VStack {
			Text("Confidence:")
				.font(.subheadline)
				.padding(.bottom,5)
			
			Picker("Confidence:",selection: $confidence) {
				Text("0.1").tag("0.1").font(.title3)
				Text("0.4").tag("0.4").font(.title3)
				Text("0.5").tag("0.5").font(.title3)
				Text("0.7").tag("0.7").font(.title3)
				Text("0.9").tag("0.9").font(.title3)
			}
			.pickerStyle(SegmentedPickerStyle())
			.padding()
			
			.onChange(of: confidence) {	tag in
				print(tag)
				self.confidencePicked =  Double(tag) ?? 0.7
			}
			
			Button(action: {
				
				analyseImage(mainImage)
				
			}) {
				Text("Analyse Image")
			}
			.padding()
			
			Image(uiImage:mainImage!)
				.resizable()
				.scaledToFit()
				.padding()
		}
		
		Text(imageDescription)
			.padding()
			.font(.footnote)
		
		Spacer()
		Button(action: {
			getImage()
		}) {
			Text("Get Random Image")
		}
		.padding()
	}
	func analyseImage(_ imageToAnalyse:UIImage?){
		
		if let image = imageToAnalyse {
			
			//following this doc
			//https://developers.google.com/ml-kit/vision/image-labeling/ios
			let visionImage = VisionImage(image: (image ?? UIImage(named: "previewImage"))!)
			visionImage.orientation = image.imageOrientation
			
			//* The confidence threshold for labels returned by the image labeler. Labels returned by the
			//* image labeler will have a confidence level higher or equal to the given threshold.
			
			let options = ImageLabelerOptions()
			options.confidenceThreshold = (self.confidencePicked) as NSNumber //0.8// (self.confidencePicked) as NSNumber //0.5
			let labeler = ImageLabeler.imageLabeler(options: options)
			
			labeler.process(visionImage) { labels, error in
				guard error == nil, let labels = labels else { return }
				
				var labelList = [String]()
				for label in labels {
					let labelText = label.text
					let confidence = label.confidence
					let confidenceFormatted = String(format: "%.2f", confidence)

					labelList.append("\(confidenceFormatted) \t \(labelText) ")
				}
				
				imageDescription = labelList.joined(separator: "\n")
			}
		}
		
	}
	func getImage() {
		let task = URLSession.shared.dataTask(with: photoURL!) { data, response, error in
			if let error = error {
				print(error)
				return
			}
			guard let httpResponse = response as? HTTPURLResponse,
				  (200...299).contains(httpResponse.statusCode) else {
				print(response ?? "Error in response")
				return
			}
			if let mimeType = httpResponse.mimeType, mimeType == "image/jpeg",
			   let data = data
			{
				DispatchQueue.main.async {
					self.mainImage = UIImage(data: data)
					analyseImage(UIImage(data: data))
				}
			}
		}
		task.resume()
	}
}

#Preview {
	ContentView()
}
