import SwiftUI

/// Enhanced section for displaying contact notes with pagination and favorites
struct NotesSection: View {
    let notes: [Note]
    let onNoteTap: ((Note) -> Void)?
    let onToggleFavorite: ((Note) -> Void)?
    let onAddNote: (() -> Void)?
    let onLoadMore: (() -> Void)?
    let hasMoreNotes: Bool
    let isLoadingMore: Bool
    
    @State private var isExpanded = true
    @State private var showingAddNote = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.medium) {
            // Section Header
            Button {
                withAnimation(.easeInOut(duration: Constants.UI.Animation.defaultDuration)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.monicaBlue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text("(\(notes.count))")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    if favoriteNotesCount > 0 {
                        Image(systemName: "star.fill")
                            .foregroundColor(.monicaGold)
                            .font(.system(size: 10))
                        
                        Text("\(favoriteNotesCount)")
                            .font(.caption2)
                            .foregroundColor(.monicaGold)
                    }
                    
                    Spacer()
                    
                    if let onAddNote = onAddNote {
                        Button(action: {
                            showingAddNote = true
                            onAddNote()
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.monicaBlue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.tertiaryText)
                        .font(.system(size: 12, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.easeInOut(duration: Constants.UI.Animation.fastDuration), value: isExpanded)
                }
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: Constants.UI.Spacing.small) {
                    if notes.isEmpty {
                        emptyStateView
                    } else {
                        notesContent
                        
                        if hasMoreNotes {
                            loadMoreButton
                        }
                    }
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(Constants.UI.Spacing.medium)
        .background(Color.secondaryBackground)
        .cornerRadius(Constants.UI.CornerRadius.medium)
    }
    
    @ViewBuilder
    private var notesContent: some View {
        VStack(spacing: 0) {
            ForEach(groupedNotes, id: \.0) { section, notes in
                NoteGroupView(
                    sectionTitle: section,
                    notes: notes,
                    onNoteTap: onNoteTap,
                    onToggleFavorite: onToggleFavorite
                )
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Constants.UI.Spacing.medium) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(.tertiaryText)
            
            Text("No Notes")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondaryText)
            
            Text("Add notes about your conversations, reminders, or any important details.")
                .font(.caption)
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
            
            if let onAddNote = onAddNote {
                Button(action: {
                    showingAddNote = true
                    onAddNote()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add First Note")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.monicaBlue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Constants.UI.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var loadMoreButton: some View {
        Button(action: {
            onLoadMore?()
        }) {
            HStack {
                if isLoadingMore {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .monicaBlue))
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.monicaBlue)
                }
                
                Text(isLoadingMore ? "Loading..." : "Load More Notes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.monicaBlue)
            }
            .padding(.vertical, Constants.UI.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoadingMore)
    }
    
    /// Group notes by favorites and recency
    private var groupedNotes: [(String, [Note])] {
        var groups: [(String, [Note])] = []
        
        let favoriteNotes = notes.filter { $0.isFavorite }
        let regularNotes = notes.filter { !$0.isFavorite }
        
        if !favoriteNotes.isEmpty {
            groups.append(("Favorites", favoriteNotes.sorted { $0.updatedAt > $1.updatedAt }))
        }
        
        if !regularNotes.isEmpty {
            let recentNotes = regularNotes.filter { isRecent($0.createdAt) }
            let olderNotes = regularNotes.filter { !isRecent($0.createdAt) }
            
            if !recentNotes.isEmpty {
                groups.append(("Recent", recentNotes.sorted { $0.createdAt > $1.createdAt }))
            }
            
            if !olderNotes.isEmpty {
                groups.append(("Older", olderNotes.sorted { $0.createdAt > $1.createdAt }))
            }
        }
        
        return groups
    }
    
    private var favoriteNotesCount: Int {
        notes.filter { $0.isFavorite }.count
    }
    
    private func isRecent(_ date: Date) -> Bool {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return date >= sevenDaysAgo
    }
}

/// View for displaying a group of notes
struct NoteGroupView: View {
    let sectionTitle: String
    let notes: [Note]
    let onNoteTap: ((Note) -> Void)?
    let onToggleFavorite: ((Note) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
            if sectionTitle != "All" {
                // Group header
                HStack {
                    Text(sectionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondaryText)
                        .padding(.horizontal)
                        .padding(.top, Constants.UI.Spacing.small)
                    
                    Spacer()
                    
                    Text("\(notes.count)")
                        .font(.caption2)
                        .foregroundColor(.tertiaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.tertiaryBackground)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.top, Constants.UI.Spacing.small)
                }
            }
            
            // Individual notes
            VStack(spacing: 0) {
                ForEach(notes) { note in
                    NoteRow(
                        note: note,
                        onTap: {
                            onNoteTap?(note)
                        },
                        onToggleFavorite: {
                            onToggleFavorite?(note)
                        }
                    )
                    
                    if note.id != notes.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
}

/// Enhanced individual note row with favorite and interaction support
struct NoteRow: View {
    let note: Note
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.UI.Spacing.medium) {
                // Note content
                VStack(alignment: .leading, spacing: Constants.UI.Spacing.extraSmall) {
                    if let title = note.title, !title.isEmpty {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                            .lineLimit(1)
                    }
                    
                    Text(note.body)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata
                    HStack {
                        Text(DateFormatting.timeAgo(from: note.updatedAt))
                            .font(.caption2)
                            .foregroundColor(.tertiaryText)
                        
                        if note.createdAt != note.updatedAt {
                            Text("• edited")
                                .font(.caption2)
                                .foregroundColor(.tertiaryText)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Favorite button
                Button(action: onToggleFavorite) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .foregroundColor(note.isFavorite ? .monicaGold : .tertiaryText)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, Constants.UI.Spacing.small)
            .padding(.vertical, Constants.UI.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Constants.UI.Spacing.medium) {
            NotesSection(
                notes: Note.mockNotes,
                onNoteTap: { note in
                    print("Tapped on note: \(note.title ?? "Untitled")")
                },
                onToggleFavorite: { note in
                    print("Toggled favorite for: \(note.title ?? "Untitled")")
                },
                onAddNote: {
                    print("Add note tapped")
                },
                onLoadMore: {
                    print("Load more notes")
                },
                hasMoreNotes: true,
                isLoadingMore: false
            )
        }
        .padding()
    }
    .background(Color.primaryBackground)
}

// MARK: - Extensions for Preview
extension Note {
    static var mockNotes: [Note] {
        [
            Note(
                id: 1,
                contactId: 1,
                title: "Important Meeting Notes",
                body: "Discussed the quarterly goals and upcoming project deadlines. Need to follow up on the budget approval by next week.",
                isFavorite: true,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            Note(
                id: 2,
                contactId: 1,
                title: "Personal Reminder",
                body: "Remember to send birthday wishes next month. Also, they mentioned wanting to visit the new restaurant downtown.",
                isFavorite: false,
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            Note(
                id: 3,
                contactId: 1,
                title: nil,
                body: "Quick note from our phone call - they're planning a vacation to Europe this summer and looking for recommendations.",
                isFavorite: false,
                createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
            )
        ]
    }
}