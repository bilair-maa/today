import SwiftUI

// The main screen. Shows today's tasks, progress, and handles the day lifecycle
// (onboarding, new day welcome, celebration animations).
struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme

    @State private var activeSheet: SheetType?
    @State private var celebration: CelebrationState?
    @State private var showingWelcome = false
    @State private var showingOnboarding = false
    @State private var selectedCategoryFilters: Set<String> = []
    @State private var isReordering = false
    @State private var showingCompletedTasks = false

    private enum SheetType: Identifiable {
        case addTask
        case settings
        case viewTask(Task)

        var id: String {
            switch self {
            case .addTask: return "addTask"
            case .settings: return "settings"
            case .viewTask(let task): return "viewTask-\(task.id)"
            }
        }
    }

    private var colors: TodayColors {
        .colors(for: settings.palette, scheme: settings.effectiveColorScheme(from: colorScheme))
    }

    // Applies the category filter chips to the sorted task list
    private var displayedTasks: [Task] {
        let sorted = viewModel.sortedTasks
        if selectedCategoryFilters.isEmpty {
            return sorted
        }
        return sorted.filter { selectedCategoryFilters.contains($0.category.name.lowercased()) }
    }

    private var allDone: Bool {
        !viewModel.tasks.isEmpty && viewModel.tasks.allSatisfy(\.isCompleted)
    }

    private var completedCount: Int {
        viewModel.tasks.filter(\.isCompleted).count
    }

    // Categories that actually appear on current tasks, used for filter chips
    private var usedCategories: [Category] {
        var seen = Set<String>()
        var result: [Category] = []
        for task in viewModel.sortedTasks {
            let key = task.category.name.lowercased()
            if seen.insert(key).inserted {
                result.append(task.category)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                dateHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                if viewModel.tasks.isEmpty {
                    Spacer()
                    EmptyStateView()
                    Spacer()
                } else if allDone {
                    if showingCompletedTasks {
                        completedTasksHeader
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                            .padding(.bottom, 6)

                        if usedCategories.count > 1 {
                            categoryFilterChips
                                .padding(.bottom, 6)
                        }

                        taskList
                        Spacer(minLength: 0)
                    } else {
                        Spacer()
                        completionView
                        Spacer()
                    }
                } else {
                    progressSection
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    if usedCategories.count > 1 {
                        categoryFilterChips
                            .padding(.bottom, 6)
                    }

                    taskList
                    Spacer(minLength: 0)
                }

                addButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            if let current = celebration {
                CelebrationView(
                    state: current,
                    colors: colors
                ) {
                    if celebration?.id == current.id {
                        celebration = nil
                    }
                }
                .id(current.id)
                .zIndex(0.5)
            }

            if showingWelcome {
                NewDayWelcomeView(colors: colors) {
                    showingWelcome = false
                }
                .zIndex(1)
            }

            if showingOnboarding {
                OnboardingView(
                    colors: colors,
                    keepBackground: settings.shouldShowNewDayWelcome
                ) {
                    settings.hasCompletedOnboarding = true
                    if settings.shouldShowNewDayWelcome {
                        showingWelcome = true
                        settings.markWelcomeShown()
                    }
                    showingOnboarding = false
                }
                .environmentObject(settings)
                .zIndex(2)
            }
        }
        .onAppear {
            viewModel.onAppLaunch(dayStartHour: settings.dayStartHour)
            if !settings.hasCompletedOnboarding {
                showingOnboarding = true
            } else if settings.shouldShowNewDayWelcome {
                showingWelcome = true
                settings.markWelcomeShown()
            }
            if settings.notificationsEnabled {
                viewModel.refreshNotifications(dayStartHour: settings.dayStartHour)
            }
        }
        .onChange(of: viewModel.tasks.count) { _ in
            if settings.notificationsEnabled {
                viewModel.refreshNotifications(dayStartHour: settings.dayStartHour)
            }
        }
        .onChange(of: allDone) { done in
            if !done {
                showingCompletedTasks = false
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addTask:
                AddTaskView(viewModel: viewModel)
                    .environmentObject(settings)
                    .preferredColorScheme(settings.preferredColorScheme)
            case .settings:
                SettingsView(viewModel: viewModel)
                    .environmentObject(settings)
                    .preferredColorScheme(settings.preferredColorScheme)
            case .viewTask(let task):
                AddTaskView(viewModel: viewModel, editingTask: task, startInViewMode: true)
                    .environmentObject(settings)
                    .preferredColorScheme(settings.preferredColorScheme)
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dayOfWeekString())
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(colors.fgMuted)

                Text(dateString())
                    .font(.system(size: 58, weight: .regular, design: .serif))
                    .tracking(-0.5)
                    .foregroundStyle(colors.fg)
            }

            Spacer()

            Button {
                activeSheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(colors.fgMuted)
                    .frame(width: 40, height: 40)
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        HStack {
            Text("\(completedCount) of \(viewModel.tasks.count) Done")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(colors.fgMuted)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: completedCount)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isReordering.toggle()
                }
            } label: {
                Image(systemName: isReordering ? "checkmark" : "line.3.horizontal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isReordering ? colors.fg : colors.fgMuted)
                    .frame(width: 36, height: 36)
                    .background(isReordering ? colors.surfaceAlt : Color.clear)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "all", isSelected: selectedCategoryFilters.isEmpty) {
                    selectedCategoryFilters = []
                }

                ForEach(usedCategories) { category in
                    let key = category.name.lowercased()
                    filterChip(label: key, isSelected: selectedCategoryFilters.contains(key)) {
                        if selectedCategoryFilters.contains(key) {
                            selectedCategoryFilters.remove(key)
                        } else {
                            selectedCategoryFilters.insert(key)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .tracking(0.3)
                .foregroundStyle(isSelected ? colors.bg : colors.fgMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? colors.fg : colors.surfaceAlt)
                .clipShape(Capsule())
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 0) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(colors.done)
                .padding(.bottom, 20)

            Text("That\u{2019}s everything for today.")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .tracking(-0.3)
                .foregroundStyle(colors.fg)
                .multilineTextAlignment(.center)

            Text("Rest counts too. The list resets at \(resetTimeString).")
                .font(.system(size: 17))
                .foregroundStyle(colors.fgMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingCompletedTasks = true
                }
            } label: {
                Text("See Tasks")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(colors.fgMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colors.hairline, lineWidth: 1)
                    }
            }
            .padding(.top, 24)
        }
        .padding(.horizontal, 32)
    }

    private var completedTasksHeader: some View {
        HStack {
            Text("\(viewModel.tasks.count) of \(viewModel.tasks.count) Done")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(colors.done)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingCompletedTasks = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(colors.fgMuted)
                    .frame(width: 36, height: 36)
                    .background(colors.surfaceAlt)
                    .clipShape(Circle())
            }
        }
    }

    private var resetTimeString: String {
        let hour = settings.dayStartHour
        if hour == 0 { return "midnight" }
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return "\(h) \(period)"
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(displayedTasks) { task in
                VStack(spacing: 0) {
                    TaskRowView(task: task, onToggle: {
                        handleToggle(task)
                    }, onTap: {
                        activeSheet = .viewTask(task)
                    })

                    Rectangle()
                        .fill(colors.divider)
                        .frame(height: 0.5)
                        .padding(.horizontal, 24)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.removeTask(task)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onMove { source, destination in
                var tasks = displayedTasks
                tasks.move(fromOffsets: source, toOffset: destination)
                viewModel.reorderTasks(tasks.map(\.id))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
    }

    // MARK: - Add Button (FAB)

    private var addButton: some View {
        Button {
            activeSheet = .addTask
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .semibold))
                Text(addButtonLabel)
                    .font(.system(size: 19, weight: .medium))
            }
            .foregroundStyle(colors.bg)
            .frame(maxWidth: (viewModel.tasks.isEmpty || (allDone && !showingCompletedTasks)) ? .infinity : nil)
            .frame(height: 54)
            .padding(.horizontal, (viewModel.tasks.isEmpty || (allDone && !showingCompletedTasks)) ? 0 : 28)
            .background(colors.fg)
            .clipShape(Capsule())
        }
    }

    private var addButtonLabel: String {
        if viewModel.tasks.isEmpty {
            return "Add the first one"
        } else if allDone {
            return "Feeling ambitious?"
        } else {
            return "Add a task"
        }
    }

    // MARK: - Toggle Logic

    // Toggles completion, triggers haptics, and shows a celebration if appropriate
    private func handleToggle(_ task: Task) {
        let wasCompleted = task.isCompleted

        withAnimation(.easeOut(duration: 0.32)) {
            viewModel.toggleCompleted(task)
        }

        if !wasCompleted {
            let done = completedCount
            let total = viewModel.tasks.count
            let allDone = done == total

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if allDone {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }

            celebration = CelebrationState(
                message: motivationalMessage(completed: done, total: total),
                isAllDone: allDone
            )
        }

        if settings.notificationsEnabled {
            viewModel.refreshNotifications(dayStartHour: settings.dayStartHour)
        }
    }

    // Picks a message based on how far along the user is
    private func motivationalMessage(completed: Int, total: Int) -> String {
        if completed == total {
            return "You did it!"
        }
        let progress = Double(completed) / Double(max(total, 1))
        let options: [String]
        if progress <= 0.25 {
            options = ["Great start!", "Let\u{2019}s go!", "One down!"]
        } else if progress <= 0.5 {
            options = ["Keep going!", "Nice work!", "Making progress!"]
        } else if progress <= 0.75 {
            options = ["Halfway there!", "Keep it up!", "Nice momentum!"]
        } else {
            options = ["Almost there!", "So close!", "Nearly done!"]
        }
        return options[completed % options.count]
    }

    // MARK: - Formatters

    private func dayOfWeekString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: adjustedDate(dayStartHour: settings.dayStartHour)).uppercased()
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: adjustedDate(dayStartHour: settings.dayStartHour))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
}
