//
//  RiskCounter.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-09.
//

import SwiftUI
import Vision

struct RiskCounter: View {
    // MARK: Frame Analysis Skipping
    @State private var image: CGImage? = nil {
        didSet {
            if !imageReceived { imageReceived = true }
            
            if source != .live {
                count()
                return
            }

            liveImageUpdates += 1
            
            if liveImageUpdates % liveUpdatesToSkip != 0 {
                return
            }
            
            count()
        }
    }
    
    @State private var imageReceived = false
    @State private var liveImageUpdates = 0
    @State private var liveUpdatesToSkip = 15
    
    // MARK: Data and Image Collection
    
    @State private var tempPickerImage: UIImage? = nil
    @State private var showingError = false
    @State private var error: String = ""
    @State private var picking = false
    @StateObject private var counter = RiskEngine.Counter()
    
    private enum Source: String, CaseIterable {
        case live = "Live"
        case camera = "Camera"
        case photos = "Photos"
        
        var image: String {
            switch self {
            case .live:
                return "record.circle"
            case .camera:
                return "camera"
            case .photos:
                return "photo"
            }
        }
    }
    
    @State private var source = Source.live
    @StateObject private var cameraObserver = CameraObserver.shared
    @State private var observations = [VNRecognizedObjectObservation]()
    
    private var totalValue: Int {
        return observations
            .compactMap(\.labels.first)
            .map(\.identifier)
            .compactMap { Int($0) }
            .reduce(0, { $0 + $1 })
    }
    
    private var sourcePicker: some View {
        HStack {
            Image(systemName: source.image)
                .frame(width: 40)
            
            Picker("Source", selection: $source) {
                ForEach(Source.allCases, id: \.hashValue) { source in
                    Text(source.rawValue)
                        .tag(source)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: source) { _ in sourceChanged() }
        }
    }
    
    private var modelPicker: some View {
        Picker("Model Version", selection: $counter.currentModel) {
            ForEach(RiskEngine.Counter.Model.allCases, id: \.hashValue) { model in
                Text(model.rawValue)
                    .tag(model)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    sourcePicker
                    modelPicker
                    
                    Text("Recognized Objects: \(observations.count)")
                    Text("Total Value: \(totalValue)")
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                
                imageView
                
                Spacer()
            }
            .navigationTitle("Risk Pieces Counter")
            .alert("Error", isPresented: $showingError, actions: {
                Button("OK") { }
            })
            .sheet(isPresented: $picking, content: {
                ImagePicker(image: $tempPickerImage, useCamera: source == .camera)
                    .ignoresSafeArea()
            })
        }
        .onDisappear {
            cameraObserver.active = false
        }
        .onAppear {
            cameraObserver.active = true
        }
    }
    
    // MARK: Drawing View
    
    private var imageView: some View {
        Button(action: {
            picking = true
            
            #if os(iOS)
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.prepare()
            gen.impactOccurred()
            #endif
        }) {
            ZStack {
                Rectangle()
                    .foregroundColor(.primary.opacity(0.2))
                
                VStack {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 50)
                    
                    if !imageReceived {
                        ProgressView()
                    }
                }
                
                // MARK: Canvas
                
                if let image {
                    let color = Color.green.opacity(0.8)
                    
                    Canvas { context, size in
                        var rect = CGRect.zero
                        
                        // Calculate rect for the image so it scales proportionately to fill the canvas.
                        
                        let imageWidth = CGFloat(image.width)
                        let imageHeight = CGFloat(image.height)

                        rect.size.width = size.width
                        let ratio = imageHeight / imageWidth
                        rect.size.height = ratio * size.width
                        rect.origin.y = min((imageHeight - rect.size.height) / 2, 0)

                        if rect.size.height < size.height {
                            rect.size.height = size.height
                            let ratio = imageWidth / imageHeight
                            rect.size.width = ratio * size.height
                            rect.origin.x = min((imageWidth - rect.size.width) / 2, 0)
                        }
                        
                        context.draw(Image(image, scale: 1.0, label: Text("")), in: rect)
                        
                        for observation in observations {
                            var denormalized = denormalizedRect(for: observation, in: rect.size)
                            denormalized.origin.x += rect.origin.x
                            denormalized.origin.y += rect.origin.y
                            let path = strokedPath(for: denormalized)
                            
                            context.stroke(path, with: .color(color), lineWidth: 3)
                            
                            let label = observation.labels.first
                            let pieceValue = label?.identifier ?? String(localized: "Unknown")
                            let confidence = round(10 * (label?.confidence ?? 0)) / 10
                            
                            var string = AttributedString(stringLiteral: "\(pieceValue)\n\(confidence)")
                            string.foregroundColor = color
                            let style = NSMutableParagraphStyle()
                            style.alignment = .center
                            string.paragraphStyle = style
                            
                            let center = CGPoint(x: denormalized.midX, y: denormalized.midY)
                            
                            context.draw(.init(string), at: center, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: 400)
            .clipped()
        }
        .disabled(source == .live)
        .onReceive(cameraObserver.$liveImage, perform: updateWithLive)
        .onChange(of: tempPickerImage) { _ in updateWithTemp() }
    }
    
    private func denormalizedRect(for observation: VNRecognizedObjectObservation, in size: CGSize) -> CGRect {
        var box = observation.boundingBox
        box.origin.x *= size.width
        box.origin.y *= size.height
        box.size.width *= size.width
        box.size.height *= size.height
        return box
    }
    
    private func strokedPath(for box: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: box.origin.x, y: box.origin.y))
            path.addLine(to: CGPoint(x: box.minX, y: box.maxY))
            path.addLine(to: CGPoint(x: box.maxX, y: box.maxY))
            path.addLine(to: CGPoint(x: box.maxX, y: box.minY))
            path.addLine(to: CGPoint(x: box.minX, y: box.minY))
            path.addLine(to: CGPoint(x: box.minX, y: box.maxY))
        }
    }
    
    // MARK: Image Methods
    
    private func sourceChanged() {
        // This heavily improves performance as it pauses or unpauses the active AVCaptureSession depending on whether it is needed.
        cameraObserver.active = source == .live
        
        // Wait for AVCaptureSession to finish so removing the image will not just cause it to be replaced by a new one.
        // This isn't a perfect way of doing this, but works for the most part.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.image = nil
        }
    }
    
    private func updateWithLive(_ image: CGImage?) {
        self.image = image
    }
    
    private func updateWithTemp() {
        if let tempPickerImage {
            if let ci = CIImage(image: tempPickerImage) {
                let cg = CIContext().createCGImage(ci, from: ci.extent)
                self.image = cg
                return
            }
        }
        
        self.image = nil
    }
    
    private func count() {
        observations = []
        guard let image else { return }
        
        do {
            self.observations = try counter.detectObjects(image: image)
        } catch {
            self.error = error.localizedDescription
            self.showingError = true
        }
    }
}

struct RiskCounter_Previews: PreviewProvider {
    static var previews: some View {
        RiskCounter()
    }
}
