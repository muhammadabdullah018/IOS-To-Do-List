import SwiftUI
import UniformTypeIdentifiers
import SkydayKit

struct SettingsView: View {
    @Environment(SkydayStore.self) private var store
    @Environment(NotificationService.self) private var notifications
    @Environment(\.dismiss) private var dismiss

    @State private var showImporter = false
    @State private var pendingImport: Data?
    @State private var confirmErase = false
    @State private var exportURL: URL?
    @State private var message: String?
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your first name (optional)", text: $name)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .onSubmit(saveName)
                } header: {
                    Text("Greeting")
                } footer: {
                    Text("Used only for the greeting on Today. Stays on this iPhone.")
                }
                goalSection
                remindersSection
                digestSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task {
                name = store.settings.displayName
                await notifications.refreshPermission()
                exportURL = makeExportFile()
            }
            .onDisappear(perform: saveName)
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let raw = try Data(contentsOf: url)
                        _ = try JSONFileStore.decode(raw) // validate before asking to replace
                        pendingImport = raw
                    } catch {
                        message = "That file isn't a Skyday backup, so nothing was changed."
                    }
                case .failure:
                    message = "The file couldn't be opened."
                }
            }
            .confirmationDialog("Replace all data with this backup?",
                                isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }),
                                titleVisibility: .visible) {
                Button("Replace my data", role: .destructive) {
                    if let raw = pendingImport {
                        do {
                            try store.importBackup(raw)
                            exportURL = makeExportFile()
                            name = store.settings.displayName
                            message = "Backup restored."
                        } catch {
                            message = "The backup couldn't be restored: \(error.localizedDescription)"
                        }
                    }
                    pendingImport = nil
                }
            } message: {
                Text("Your current tasks, lists and history are replaced. You can undo right after.")
            }
            .confirmationDialog("Erase everything?", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("Erase all data", role: .destructive) {
                    store.eraseAllData()
                    Haptics.warning()
                    dismiss()
                }
            } message: {
                Text("All tasks, lists and streak history are deleted from this iPhone. You can undo right after.")
            }
            .alert("Skyday", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) { message = nil }
            } message: {
                Text(message ?? "")
            }
        }
    }

    // MARK: Sections

    private var goalSection: some View {
        Section {
            Stepper(value: Binding(get: { store.settings.dailyGoal }, set: { store.setDailyGoal($0) }), in: AppSettings.goalRange) {
                HStack {
                    Text("Daily goal")
                    Spacer()
                    Text(store.settings.dailyGoal == 1 ? "1 task" : "\(store.settings.dailyGoal) tasks")
                        .foregroundStyle(SkyColor.inkSecondary)
                }
            }
            Picker("Week starts on", selection: Binding(get: { store.settings.firstWeekday },
                                                        set: { v in store.updateSettings { $0.firstWeekday = v } })) {
                Text("Monday").tag(2)
                Text("Sunday").tag(1)
            }
        } header: {
            Text("Goal")
        } footer: {
            Text("A day counts toward your streak when you finish this many tasks. One missed day a week is forgiven as a rest day.")
        }
    }

    private var remindersSection: some View {
        Section {
            HStack {
                Label("Notifications", systemImage: "bell.badge.fill")
                Spacer()
                switch notifications.permission {
                case .allowed:
                    Text("On").foregroundStyle(SkyColor.inkSecondary)
                case .denied:
                    Button("Turn on in Settings") { notifications.openSystemSettings() }
                case .notDetermined:
                    Button("Allow") { Task { @MainActor in await notifications.requestPermissionIfNeeded() } }
                case .unknown:
                    ProgressView()
                }
            }
            DatePicker("Date-only reminders at",
                       selection: timeBinding(get: { store.settings.defaultReminderTime },
                                              set: { t in store.updateSettings { $0.defaultReminderTime = t } }),
                       displayedComponents: .hourAndMinute)
            Toggle("Reminder sound", isOn: Binding(get: { store.settings.reminderSound },
                                                   set: { v in store.updateSettings { $0.reminderSound = v } }))
        } header: {
            Text("Reminders")
        } footer: {
            Text("Reminders arrive even when Skyday is closed. Focus modes and your iPhone's notification settings can delay or hide them.")
        }
    }

    private var digestSection: some View {
        Section {
            Toggle("Morning plan", isOn: digestToggle(\.morningDigest))
            if store.settings.morningDigest.enabled {
                DatePicker("Time", selection: digestTime(\.morningDigest), displayedComponents: .hourAndMinute)
            }
            Toggle("Evening check-in", isOn: digestToggle(\.eveningDigest))
            if store.settings.eveningDigest.enabled {
                DatePicker("Time", selection: digestTime(\.eveningDigest), displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Daily summaries")
        } footer: {
            Text("Sent only on days with tasks. Counts reflect your tasks as of the last time you used Skyday.")
        }
    }

    private var dataSection: some View {
        Section {
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export backup", systemImage: "square.and.arrow.up")
                }
            }
            Button {
                showImporter = true
            } label: {
                Label("Import backup", systemImage: "square.and.arrow.down")
            }
            Button(role: .destructive) {
                confirmErase = true
            } label: {
                Label("Erase all data", systemImage: "trash")
            }
        } header: {
            Text("Your data")
        } footer: {
            Text("Everything is stored on this iPhone only. Deleting the app deletes your data unless you export a backup.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            NavigationLink("How streaks work") { StreakRulesView() }
            NavigationLink("Privacy") { PrivacyView() }
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    .foregroundStyle(SkyColor.inkSecondary)
            }
        }
    }

    // MARK: Helpers

    private func saveName() {
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        guard trimmed != store.settings.displayName else { return }
        store.updateSettings { $0.displayName = trimmed }
    }

    private func timeBinding(get: @escaping () -> TimeOfDay, set: @escaping (TimeOfDay) -> Void) -> Binding<Date> {
        let calendar = store.calendar
        let today = store.today
        return Binding(get: { today.date(at: get(), in: calendar) },
                       set: { set(TimeOfDay($0, calendar: calendar)) })
    }

    private func digestToggle(_ key: WritableKeyPath<AppSettings, DigestSetting>) -> Binding<Bool> {
        Binding(get: { store.settings[keyPath: key].enabled },
                set: { on in
                    store.updateSettings { $0[keyPath: key].enabled = on }
                    if on { Task { @MainActor in await notifications.requestPermissionIfNeeded() } }
                })
    }

    private func digestTime(_ key: WritableKeyPath<AppSettings, DigestSetting>) -> Binding<Date> {
        timeBinding(get: { store.settings[keyPath: key].time },
                    set: { t in store.updateSettings { $0[keyPath: key].time = t } })
    }

    private func makeExportFile() -> URL? {
        guard let data = try? store.exportBackup() else { return nil }
        let stamp = store.today.description
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Skyday-backup-\(stamp).json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

struct StreakRulesView: View {
    var body: some View {
        List {
            rule("A day counts", "when you finish your daily goal. Tasks count on the day you complete them, even if they were due earlier.")
            rule("Rest days", "One missed day is forgiven if you haven't used a rest day in the past week. It keeps your streak alive but doesn't add to it.")
            rule("Today is never a miss", "Your streak only breaks after a day ends without reaching the goal.")
            rule("Changing your goal", "Applies from today. Past days keep the goal they had, and raising it can't un-earn today.")
            rule("Reopening a task", "Removes its credit from the day it was completed. Deleting a completed task keeps its credit.")
            rule("Repeating tasks", "Each occurrence counts once. Completing the same occurrence twice never double counts.")
            rule("Time zones", "Days are recorded when you complete tasks, so travelling never rewrites your history.")
        }
        .navigationTitle("How streaks work")
    }

    private func rule(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(body).font(.subheadline).foregroundStyle(SkyColor.inkSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Text("Skyday has no account, no analytics, no ads and no servers. Your tasks, lists and history stay on this iPhone.")
            Text("The Home Screen widget reads a small summary stored in the app's shared container on this device.")
            Text("Reminders are scheduled locally with iOS notifications. Notification previews on the Lock Screen follow your iOS settings.")
            Text("Backups you export are plain JSON files that you control.")
        }
        .navigationTitle("Privacy")
    }
}
