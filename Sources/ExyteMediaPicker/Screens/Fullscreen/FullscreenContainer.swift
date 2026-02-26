//
//  Created by Alex.M on 09.06.2022.
//
//  FIX: Fullscreen viewer stuck in top-left on iPhone 17 Pro Max (and other large devices).
//  Apply this file to: https://github.com/JustinMondal/MediaPicker
//  Path: Sources/ExyteMediaPicker/Screens/Fullscreen/FullscreenContainer.swift
//

import Foundation
import SwiftUI
import AnchoredPopup

struct FullscreenContainer: View {

    @EnvironmentObject private var selectionService: SelectionService
    @Environment(\.mediaPickerTheme) private var theme

    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper.shared

    @Binding var currentFullscreenMedia: Media?
    @Binding var selection: AssetMediaModel.ID?
    let animationID: String
    let assetMediaModels: [AssetMediaModel]
    var selectionParamsHolder: SelectionParamsHolder
    var dismiss: ()->()
    /// When non-nil, fullscreen is presented via fullScreenCover; close uses this instead of AnchoredPopup (fixes top-left bug on iPhone 17 Pro Max etc.).
    var onCloseFullscreen: (() -> Void)? = nil

    private var selectedMediaModel: AssetMediaModel? {
        assetMediaModels.first { $0.id == selection }
    }

    private var selectionServiceIndex: Int? {
        guard let selectedMediaModel = selectedMediaModel else {
            return nil
        }
        return selectionService.index(of: selectedMediaModel)
    }

    /// Use explicit screen size so the fullscreen viewer fills the screen on all devices (e.g. iPhone 17 Pro Max).
    /// AnchoredPopup can propose a wrong size on some screen sizes; this forces correct layout.
    private var screenSize: CGSize {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow }) else {
            return UIScreen.main.bounds.size
        }
        return window.bounds.size
    }

    var body: some View {
        VStack {
            controlsOverlay
            GeometryReader { g in
                contentView(g.size)
            }
        }
        .frame(width: onCloseFullscreen == nil ? screenSize.width : nil,
               height: onCloseFullscreen == nil ? screenSize.height : nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaPadding(.top, UIApplication.safeArea.top)
        .background {
            theme.main.fullscreenPhotoBackground
                .ignoresSafeArea()
        }
        .onAppear {
            if let selectedMediaModel {
                currentFullscreenMedia = Media(source: selectedMediaModel)
            }
        }
        .onDisappear {
            currentFullscreenMedia = nil
        }
        .onChange(of: selection) {
            if let selectedMediaModel {
                currentFullscreenMedia = Media(source: selectedMediaModel)
            }
        }
        .onTapGesture {
            if keyboardHeightHelper.keyboardDisplayed {
                dismissKeyboard()
            } else {
                if let selectedMediaModel = selectedMediaModel, selectedMediaModel.mediaType == .image {
                    selectionService.onSelect(assetMediaModel: selectedMediaModel)
                }
            }
        }
    }

    @ViewBuilder
    func contentView(_ size: CGSize) -> some View {
        if #available(iOS 17.0, *) {
            ScrollViewReader { scrollReader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(assetMediaModels, id: \.id) { assetMediaModel in
                            FullscreenCell(viewModel: FullscreenCellViewModel(mediaModel: assetMediaModel), size: size)
                                .frame(width: size.width, height: size.height)
                                .id(assetMediaModel.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selection)
                .onAppear {
                    scrollReader.scrollTo(selection)
                }
            }
        } else {
            TabView(selection: $selection) {
                ForEach(assetMediaModels, id: \.id) { assetMediaModel in
                    FullscreenCell(viewModel: FullscreenCellViewModel(mediaModel: assetMediaModel), size: size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(assetMediaModel.id)
                }
            }
        }
    }

    var controlsOverlay: some View {
        HStack {
            Image(systemName: "xmark")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(20, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let close = onCloseFullscreen {
                        close()
                    } else {
                        selection = nil
                        AnchoredPopup.launchShrinkingAnimation(id: animationID)
                    }
                }

            Spacer()

            if let selectedMediaModel = selectedMediaModel {
                if selectionParamsHolder.selectionLimit == 1 {
                    Button("Select") {
                        if let close = onCloseFullscreen {
                            close()
                        } else {
                            AnchoredPopup.launchShrinkingAnimation(id: animationID)
                        }
                        selectionService.onSelect(assetMediaModel: selectedMediaModel)
                        dismiss()
                    }
                    .padding(.horizontal, 20)
                } else {
                    SelectionIndicatorView(index: selectionServiceIndex, isFullscreen: true, canSelect: selectionService.canSelect(assetMediaModel: selectedMediaModel), selectionParamsHolder: selectionParamsHolder)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            selectionService.onSelect(assetMediaModel: selectedMediaModel)
                        }
                }
            }
        }
        .foregroundStyle(theme.selection.fullscreenSelectedBackground)
    }
}
