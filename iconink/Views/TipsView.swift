import SwiftUI

struct TipsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header section
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        
                        Text("ID Scanning Tips")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
                    
                    // Tips sections
                    tipSection(
                        title: "Lighting & Environment",
                        icon: "sun.max.fill",
                        color: .orange,
                        tips: [
                            "Ensure even lighting on the entire ID",
                            "Avoid harsh shadows or direct glare",
                            "Use natural daylight when possible",
                            "Avoid very dark or very bright areas"
                        ]
                    )
                    
                    tipSection(
                        title: "ID Positioning",
                        icon: "rectangle.and.hand.point.up.left.fill",
                        color: .blue,
                        tips: [
                            "Place ID on a contrasting background",
                            "Ensure the entire ID is within the frame",
                            "Keep the ID flat and avoid angles",
                            "Make sure all text is clearly visible"
                        ]
                    )
                    
                    tipSection(
                        title: "Camera & Focus",
                        icon: "camera.fill",
                        color: .green,
                        tips: [
                            "Keep the camera steady during capture",
                            "Ensure the ID is in focus before capturing",
                            "Capture from 8-12 inches away for best results",
                            "Wait for the autofocus to adjust before capturing"
                        ]
                    )
                    
                    tipSection(
                        title: "ID Document",
                        icon: "doc.text.fill",
                        color: .purple,
                        tips: [
                            "Remove ID from wallet or sleeve",
                            "Wipe the ID clean of fingerprints or smudges",
                            "For damaged IDs, enter information manually",
                            "For IDs with holographic elements, adjust angle to minimize reflection"
                        ]
                    )
                    
                    tipSection(
                        title: "When Scanning Fails",
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        tips: [
                            "Try the alternative processing option",
                            "Take multiple photos from slightly different angles",
                            "Increase brightness in dark environments",
                            "For reflective IDs, try adjusting the angle to reduce glare",
                            "As a last resort, enter information manually"
                        ]
                    )
                    
                    // Examples section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            
                            Text("Good Examples")
                                .font(.headline)
                        }
                        
                        Text("• Well-lit ID with no glare")
                        Text("• ID placed on dark background")
                        Text("• Camera held steady directly above")
                        Text("• ID completely in frame")
                        
                        HStack {
                            Image(systemName: "xmark.seal.fill")
                                .foregroundColor(.red)
                            
                            Text("Poor Examples")
                                .font(.headline)
                        }
                        .padding(.top, 8)
                        
                        Text("• Poor lighting or shadows")
                        Text("• ID at an angle or partially cut off")
                        Text("• Blurry or out of focus")
                        Text("• Excessive glare or reflections")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitle("Scanning Tips", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    /// Creates a section of tips with a consistent style
    private func tipSection(title: String, icon: String, color: Color, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
            }
            
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(color)
                    Text(tip)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TipsView_Previews: PreviewProvider {
    static var previews: some View {
        TipsView(isPresented: .constant(true))
    }
} 