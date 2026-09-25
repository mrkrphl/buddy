import PhotosUI
import SwiftUI
import UIKit

struct PlatePhotoCapture: View {
    var onImage: (UIImage) -> Void

    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                Label("Log plate", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BuddyTheme.needle, in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                    .foregroundStyle(BuddyTheme.bone)
            }
            .buttonStyle(PressableButtonStyle())

            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3.weight(.semibold))
                    .frame(width: 56, height: 56)
                    .background(BuddyTheme.bone.opacity(0.08), in: RoundedRectangle(cornerRadius: BuddyTheme.radiusMD, style: .continuous))
                    .foregroundStyle(BuddyTheme.bone)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                onImage(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImage(image)
                }
                photoItem = nil
            }
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }
    }
}
