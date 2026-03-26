import PhotosUI
import SwiftUI
import UIKit

private struct PhotoSlotCard: View {
    let index: Int
    let photo: DefectPhoto?
    let onRemove: (() -> Void)?

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.92))
            .frame(height: 110)
            .overlay {
                HStack(spacing: 14) {
                    if let photo, let previewImage = photo.previewImage {
                        previewImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 78, height: 78)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DesignTokens.Colors.surface)
                            .frame(width: 78, height: 78)
                            .overlay {
                                Image(systemName: "plus.viewfinder")
                                    .font(.title2)
                                    .foregroundStyle(DesignTokens.Colors.accent)
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(photo?.filename ?? "Добавить фото")
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text(photo == nil ? "Выберите изображение из галереи" : "Изображение готово к проверке")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.muted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 12) {
                        Text("\(index + 1)/3")
                            .foregroundStyle(DesignTokens.Colors.muted)

                        if photo != nil, let onRemove {
                            Button("Убрать", action: onRemove)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
    }
}

struct DefectReportView: View {
    let inspectionId: String
    let planElement: PlanElement
    let submitReportUseCase: SubmitReportUseCase

    @State private var comment = ""
    @State private var photos: [DefectPhoto] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isSubmitting = false
    @State private var result: VerificationResult?
    @State private var photoLoadError: String?
    @State private var isPresentingCamera = false
    @State private var verificationError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(planElement.title)
                        .font(.largeTitle.bold())
                    Text("Категория: \(planElement.kind.rawValue)")
                        .foregroundStyle(DesignTokens.Colors.muted)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Фото")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Button {
                            photoLoadError = nil
                            isPresentingCamera = true
                        } label: {
                            HStack {
                                Label("Камера", systemImage: "camera")
                                Spacer()
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }

                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: max(0, 3 - photos.count),
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack {
                                Label("Галерея", systemImage: "photo.on.rectangle.angled")
                                Spacer()
                                Text("\(photos.count)/3")
                                    .foregroundStyle(DesignTokens.Colors.muted)
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .disabled(photos.count >= 3)

                    ForEach(0..<3, id: \.self) { index in
                        PhotoSlotCard(
                            index: index,
                            photo: index < photos.count ? photos[index] : nil,
                            onRemove: index < photos.count ? { removePhoto(at: index) } : nil
                        )
                    }

                    if let photoLoadError {
                        Text(photoLoadError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Комментарий")
                        .font(.headline)

                    TextField(
                        "Опишите дефект словами, например: трещина на откосе окна, скол краски справа",
                        text: $comment,
                        axis: .vertical
                    )
                    .lineLimit(4...6)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .tint(DesignTokens.Colors.accent)
                    .padding(16)
                    .background(.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DesignTokens.Colors.ink.opacity(0.08), lineWidth: 1)
                    }
                }

                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    HStack {
                        Text(isSubmitting ? "Проверяем..." : "Проверить дефект")
                        Spacer()
                        Image(systemName: "sparkles")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(DesignTokens.Colors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .disabled(isSubmitting)

                if let verificationError {
                    Text(verificationError)
                        .font(.caption.monospaced())
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !photos.isEmpty {
                    Text("Фото автоматически уменьшаются перед отправкой, чтобы проверка на реальном iPhone проходила стабильнее.")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.muted)
                }

                if photos.isEmpty {
                    Text("Для MVP можно отправить и без фото, но AI-результат будет менее надёжным.")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.muted)
                }

                if let result {
                    VerificationResultCard(result: result)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [DesignTokens.Colors.surface, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Дефект")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadPhotos(from: newItems)
            }
        }
        .sheet(isPresented: $isPresentingCamera) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                CameraCaptureView { image in
                    appendCapturedPhoto(image)
                }
                .ignoresSafeArea()
            } else {
                cameraUnavailableView
                    .presentationDetents([.medium])
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        verificationError = nil
        defer { isSubmitting = false }

        let draft = DefectReportDraft(
            id: UUID().uuidString,
            inspectionId: inspectionId,
            planElement: planElement,
            comment: comment,
            photos: photos
        )

        do {
            result = try await submitReportUseCase.execute(draft: draft)
        } catch {
            result = nil
            verificationError = error.localizedDescription
        }
    }

    private func removePhoto(at index: Int) {
        photos.remove(at: index)
    }

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }

        photoLoadError = nil
        var nextPhotos = photos

        for item in items {
            guard nextPhotos.count < 3 else { break }

            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let photo = DefectPhoto.optimized(
                        data: data,
                        filename: item.itemIdentifier ?? "photo_\(nextPhotos.count + 1).jpg"
                    ) {
                        nextPhotos.append(photo)
                    } else {
                        photoLoadError = "Не удалось подготовить одно из изображений к отправке."
                    }
                }
            } catch {
                photoLoadError = "Не удалось загрузить одно из изображений. Попробуйте выбрать его ещё раз."
            }
        }

        photos = Array(nextPhotos.prefix(3))
        selectedItems = []
    }

    private func appendCapturedPhoto(_ image: UIImage) {
        guard photos.count < 3 else { return }

        guard let photo = DefectPhoto.optimized(
            image: image,
            filename: "camera_\(photos.count + 1).jpg"
        ) else {
            photoLoadError = "Не удалось обработать снимок с камеры."
            return
        }

        photos.append(photo)
        photoLoadError = nil
    }

    private var cameraUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 36))
                .foregroundStyle(DesignTokens.Colors.muted)

            Text("Камера недоступна")
                .font(.headline)

            Text("На симуляторе камера не работает. Для этого режима нужен реальный iPhone.")
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignTokens.Colors.muted)
                .padding(.horizontal, 24)

            Button("Закрыть") {
                isPresentingCamera = false
            }
            .font(.headline)
        }
        .padding(24)
    }
}
