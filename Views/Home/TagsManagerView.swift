// TagsManagerView.swift
// Tags manager sheet for tags

import SwiftUI
import SwiftData

struct TagsManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    @State private var newTagName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        TextField("New Tag Name", text: $newTagName)
                            .padding()
                            .background(.ultraThinMaterial.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white)

                        Button("Add") {
                            let clean = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !clean.isEmpty else { return }
                            let tag = Tag(name: clean)
                            modelContext.insert(tag)
                            try? modelContext.save()
                            newTagName = ""
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.primaryStart)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding()

                    List {
                        ForEach(tags) { tag in
                            Text(tag.name)
                                .foregroundColor(.white)
                                .listRowBackground(Color.white.opacity(0.06))
                        }
                        .onDelete { indices in
                            for idx in indices {
                                modelContext.delete(tags[idx])
                            }
                            try? modelContext.save()
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Tags Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
