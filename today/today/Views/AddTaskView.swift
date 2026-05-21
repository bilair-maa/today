import SwiftUI

// Handles creating new tasks and editing/viewing existing ones.
// Uses a half-sheet that expands to full screen for the complete form.
struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var editingTask: Task?
    var startInViewMode: Bool = false

    @State private var title = ""
    @State private var descriptionText = ""
    @State private var selectedCategory: Category?
    @State private var selectedPriority: Priority = .medium
    @State private var hasExpiration = false
    @State private var expirationTime = Date()
    @State private var expirationError: String?
    @State private var selectedReminder: ReminderOffset?
    @State private var isAddingCustomCategory = false
    @State private var customCategoryName = ""
    @State private var customCategoryError: String?
    @State private var renamingCategory: Category?
    @State private var renameCategoryName = ""
    @State private var isViewMode = false
    private static let collapsedDetent: PresentationDetent = .height(370)
    private static let viewDetent: PresentationDetent = .height(320)
    @State private var currentDetent: PresentationDetent = collapsedDetent
    @FocusState private var customCategoryFocused: Bool
    @FocusState private var titleFocused: Bool

    private var isEditing: Bool { editingTask != nil }
    private var isExpanded: Bool { currentDetent != Self.collapsedDetent }

    private var colors: TodayColors {
        .colors(for: settings.palette, scheme: settings.effectiveColorScheme(from: colorScheme))
    }

    var body: some View {
        NavigationStack {
            Group {
                if isViewMode {
                    viewContent
                } else {
                    editContent
                }
            }
            .background(colors.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.surface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isViewMode {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(colors.fgMuted)
                        }
                    } else {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(colors.fgMuted)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(isViewMode ? "TASK" : (isEditing ? "EDIT" : "NEW"))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(1.4)
                        .foregroundStyle(colors.fgFaint)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isViewMode {
                        Button("Edit") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isViewMode = false
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.fg)
                    } else {
                        Button(isEditing ? "Save" : "Add") { saveTask() }
                            .fontWeight(.semibold)
                            .foregroundStyle(colors.fg)
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || expirationError != nil)
                    }
                }
            }
        }
        .presentationDetents(
            isViewMode
                ? [Self.viewDetent, .medium, .large]
                : [Self.collapsedDetent, .large],
            selection: $currentDetent
        )
        .presentationDragIndicator(.visible)
        .modifier(PresentationCornerRadiusModifier(radius: 28))
        .onAppear {
            isViewMode = startInViewMode
            if startInViewMode {
                currentDetent = Self.viewDetent
            } else if editingTask != nil {
                currentDetent = .large
            }
            if let task = editingTask {
                title = task.title
                descriptionText = task.note ?? ""
                selectedCategory = task.category
                selectedPriority = task.priority
                selectedReminder = task.reminderOffset
                if let exp = task.expirationDate {
                    hasExpiration = true
                    expirationTime = exp
                }
            } else if selectedCategory == nil {
                selectedCategory = viewModel.categories.first
            }
        }
    }

    // MARK: - View Mode

    private var viewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let task = editingTask, task.isCompleted {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Completed")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                    }
                    .foregroundStyle(colors.done)
                    .padding(.bottom, 14)
                }

                Text(title)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .tracking(-0.2)
                    .foregroundStyle(colors.fg)
                    .fixedSize(horizontal: false, vertical: true)

                FlowLayout(spacing: 6) {
                    if let category = selectedCategory {
                        Text(category.name.lowercased())
                            .foregroundStyle(colors.accentInk)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(colors.accentSoft.opacity(0.7))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(selectedPriority.color)
                            .frame(width: 6, height: 6)
                        Text(priorityLabel(selectedPriority))
                            .foregroundStyle(selectedPriority.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(selectedPriority.color.opacity(0.08))
                    .clipShape(Capsule())

                    if hasExpiration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(expirationTime, style: .time)
                        }
                        .foregroundStyle(colors.fgMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)

                        if let reminder = selectedReminder {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 10))
                                Text(reminder.label)
                            }
                            .foregroundStyle(colors.fgMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                        }
                    }
                }
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .tracking(0.3)
                .padding(.top, 14)

                if !descriptionText.isEmpty {
                    Rectangle()
                        .fill(colors.divider)
                        .frame(height: 0.5)
                        .padding(.top, 20)

                    Text(descriptionText)
                        .font(.system(size: 16))
                        .foregroundStyle(colors.fgMuted)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                }

                deleteButton
                    .padding(.top, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Edit Mode

    private var editContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TextField("what's the task?", text: $title)
                    .font(.system(size: isExpanded ? 38 : 34, weight: .regular, design: .serif))
                    .tracking(-0.3)
                    .foregroundStyle(colors.fg)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($titleFocused)
                    .onChange(of: title) { newValue in
                        if newValue.count > 280 {
                            title = String(newValue.prefix(280))
                        }
                    }

                if title.count > 200 {
                    Text("\(title.count)/280")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(title.count > 260 ? colors.warn : colors.fgFaint)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Rectangle()
                    .fill(colors.divider)
                    .frame(height: 0.5)
                    .padding(.top, 14)

                categorySection
                    .padding(.top, isExpanded ? 28 : 18)

                if isExpanded {
                    prioritySection
                        .padding(.top, 28)

                    descriptionSection
                        .padding(.top, 28)

                    expirationSection
                        .padding(.top, 28)

                    if hasExpiration {
                        reminderSection
                            .padding(.top, 28)
                    }
                } else {
                    prioritySection
                        .padding(.top, 20)

                    Text("\u{2191} pull up to expand")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundStyle(colors.fgFaint)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                }

                if isEditing {
                    deleteButton
                        .padding(.top, 32)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.automatic)
        .onChange(of: titleFocused) { focused in
            if focused && !isExpanded {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentDetent = .large
                }
            }
        }
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORY")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            FlowLayout(spacing: 6) {
                ForEach(viewModel.categories) { category in
                    categoryPill(category)
                }

                if isAddingCustomCategory {
                    VStack(alignment: .leading, spacing: 4) {
                        customCategoryField

                        if let error = customCategoryError {
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(colors.warn)
                        }
                    }
                } else if viewModel.categories.count < Self.maxCategories {
                    Button {
                        isAddingCustomCategory = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            customCategoryFocused = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("custom")
                        }
                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                        .tracking(0.3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .foregroundStyle(colors.fgMuted)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colors.hairline, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .alert("Rename Category", isPresented: Binding(
            get: { renamingCategory != nil },
            set: { if !$0 { renamingCategory = nil } }
        )) {
            TextField("name", text: $renameCategoryName)
            Button("Rename") {
                if let cat = renamingCategory {
                    let _ = viewModel.renameCategory(cat, to: renameCategoryName)
                }
                renamingCategory = nil
            }
            Button("Cancel", role: .cancel) {
                renamingCategory = nil
            }
        }
    }

    private func categoryPill(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        return Button {
            selectedCategory = category
        } label: {
            Text(category.name.lowercased())
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: .monospaced))
                .tracking(0.3)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? colors.bg : colors.fgMuted)
                .background(isSelected ? colors.accentInk : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .if(!category.isDefault) { view in
            view.contextMenu {
                Button {
                    renameCategoryName = category.name
                    renamingCategory = category
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    if selectedCategory?.id == category.id {
                        selectedCategory = viewModel.categories.first
                    }
                    viewModel.removeCategory(category)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var customCategoryField: some View {
        HStack(spacing: 4) {
            TextField("name", text: $customCategoryName)
                .focused($customCategoryFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: customCategoryName) { _ in customCategoryError = nil }
                .onSubmit { addCustomCategory() }

            Button {
                customCategoryName = ""
                customCategoryError = nil
                isAddingCustomCategory = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(colors.fgFaint)
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 15, design: .monospaced))
        .tracking(0.3)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(colors.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(width: 130)
    }

    private static let maxCategories = 8

    private func addCustomCategory() {
        let trimmed = customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if viewModel.categories.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            customCategoryError = "Category already exists."
            return
        }
        if viewModel.categories.count >= Self.maxCategories {
            customCategoryError = "Maximum \(Self.maxCategories) categories."
            return
        }
        if let category = viewModel.addCategory(name: trimmed) {
            selectedCategory = category
        }
        customCategoryName = ""
        customCategoryError = nil
        isAddingCustomCategory = false
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DESCRIPTION")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(colors.fgFaint)

                Spacer()

                if descriptionText.count > 400 {
                    Text("\(descriptionText.count)/500")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(descriptionText.count > 480 ? colors.warn : colors.fgFaint)
                }
            }

            TextEditor(text: $descriptionText)
                .font(.system(size: 18))
                .foregroundStyle(colors.fg)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100, maxHeight: 200)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .overlay(alignment: .topLeading) {
                    if descriptionText.isEmpty {
                        Text("add a description...")
                            .font(.system(size: 18))
                            .foregroundStyle(colors.fgFaint)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
                .background(colors.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: descriptionText) { newValue in
                    if newValue.count > 500 {
                        descriptionText = String(newValue.prefix(500))
                    }
                }
        }
    }

    // MARK: - Priority

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRIORITY")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            HStack(spacing: 6) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    priorityPill(priority)
                }
            }
        }
    }

    private func priorityPill(_ priority: Priority) -> some View {
        let isSelected = selectedPriority == priority
        return Button {
            selectedPriority = priority
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(priority.color)
                    .frame(width: 6, height: 6)
                Text(priorityLabel(priority))
            }
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .monospaced))
            .tracking(0.3)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : colors.fgMuted)
            .background(isSelected ? priority.color : Color.clear)
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colors.hairline, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .fixedSize()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expiration

    private var expirationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXPIRATION")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(colors.fgFaint)

                Spacer()

                if hasExpiration {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hasExpiration = false
                            expirationError = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(colors.fgFaint)
                    }
                    .buttonStyle(.plain)
                }
            }

            if hasExpiration {
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker(
                        "",
                        selection: $expirationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(height: 120)
                    .clipped()
                    .onChange(of: expirationTime) { _ in
                        adjustExpirationDate()
                    }

                    if let error = expirationError {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(colors.fgMuted)
                            .padding(.top, 4)
                    }
                }
            } else {
                Button {
                    expirationTime = Date().addingTimeInterval(3600)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hasExpiration = true
                    }
                    expirationError = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text("add time")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(colors.accentInk)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(colors.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reminder

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REMINDER")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            Menu {
                Button {
                    selectedReminder = nil
                } label: {
                    HStack {
                        Text("None")
                        if selectedReminder == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                ForEach(ReminderOffset.allCases) { offset in
                    Button {
                        selectedReminder = offset
                    } label: {
                        HStack {
                            Text(offset.label)
                            if selectedReminder == offset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bell")
                        .font(.system(size: 14))
                    Text(selectedReminder?.label ?? "None")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .tracking(0.3)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
                .foregroundStyle(selectedReminder != nil ? colors.bg : colors.fgMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(selectedReminder != nil ? colors.accentInk : Color.clear)
                .overlay {
                    if selectedReminder == nil {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(colors.hairline, lineWidth: 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button {
            if let task = editingTask {
                viewModel.removeTask(task)
                dismiss()
            }
        } label: {
            Text("Delete")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Priority.high.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Priority.high.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    // Delegates to the view model for validation, then dismisses on success
    private func saveTask() {
        let expirationDate = hasExpiration ? expirationTime : nil
        let reminder = hasExpiration ? selectedReminder : nil

        if let task = editingTask {
            let _ = viewModel.updateTask(
                task,
                title: title,
                note: descriptionText.isEmpty ? nil : descriptionText,
                expirationDate: expirationDate,
                reminderOffset: reminder,
                category: selectedCategory ?? viewModel.categories[0],
                priority: selectedPriority
            )
            dismiss()
        } else {
            guard let category = selectedCategory else { return }
            let success = viewModel.addTask(
                title: title,
                note: descriptionText.isEmpty ? nil : descriptionText,
                expirationDate: expirationDate,
                reminderOffset: reminder,
                category: category,
                priority: selectedPriority
            )
            if success { dismiss() }
        }
    }

    // MARK: - Helpers

    // Snaps the picked time to a valid point within the user's day window
    private func adjustExpirationDate() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: expirationTime)
        let minute = calendar.component(.minute, from: expirationTime)

        if let resolved = resolveTimeInDay(hour: hour, minute: minute, dayStartHour: settings.dayStartHour) {
            expirationTime = resolved
            expirationError = nil
        } else {
            expirationError = "This time is outside your day."
            let end = dayEndDate(dayStartHour: settings.dayStartHour)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                expirationTime = end.addingTimeInterval(-60)
                expirationError = nil
            }
        }
    }

    private func priorityLabel(_ priority: Priority) -> String {
        switch priority {
        case .low: return "low"
        case .medium: return "med"
        case .high: return "high"
        }
    }

}

