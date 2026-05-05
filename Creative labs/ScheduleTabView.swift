import SwiftUI

// MARK: - Schedule data model

struct ScheduleEntry: Identifiable {
    let id = UUID()
    var time: String     // "HH:MM"
    var label: String    // "Everyday", "Weekdays" etc.
    var action: String   // "Open" or "Close"
    var isEnabled: Bool
}

// MARK: - Schedule tab (inside home bottom panel)

struct ScheduleTabView: View {
    @ObservedObject var ble: BLEManager
    @State private var filter: ScheduleFilter = .upcoming
    @State private var showAdd = false
    @State private var entries: [ScheduleEntry] = [
        ScheduleEntry(time: "07:00 AM", label: "Everyday", action: "Open",  isEnabled: true),
        ScheduleEntry(time: "12:00 PM", label: "Weekdays", action: "Open",  isEnabled: true),
        ScheduleEntry(time: "09:30 PM", label: "Everyday", action: "Close", isEnabled: false),
    ]

    enum ScheduleFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case history  = "History"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter pills + add button
            HStack(spacing: 0) {
                // Segment
                HStack(spacing: 0) {
                    ForEach(ScheduleFilter.allCases, id: \.self) { f in
                        Button {
                            withAnimation { filter = f }
                        } label: {
                            Text(f.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(filter == f ? .white : .ptTextMid)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background(filter == f ? Color.ptSage : Color.clear)
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.ptSageLight.opacity(0.4))
                .cornerRadius(20)
                .padding(.leading, 16)

                Spacer()

                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.ptPinkDeep)
                        .padding(8)
                        .background(Color.ptPinkLight)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
            .padding(.vertical, 10)

            Divider().background(Color.ptDivider)

            // List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach($entries) { $entry in
                        scheduleRow(entry: $entry)
                        Divider().background(Color.ptDivider).padding(.leading, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddScheduleView { time, action in
                entries.append(ScheduleEntry(
                    time: time, label: "Everyday",
                    action: action, isEnabled: true
                ))
                ble.send(.scheduleSet(time: time))
            }
        }
    }

    func scheduleRow(entry: Binding<ScheduleEntry>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.wrappedValue.time)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.ptText)
                Text(entry.wrappedValue.label)
                    .font(.ptCaption)
                    .foregroundColor(.ptTextLight)
            }

            Spacer()

            Text(entry.wrappedValue.action)
                .font(.ptCaption)
                .foregroundColor(entry.wrappedValue.action == "Open" ? .ptSage : .ptPinkDeep)

            Toggle("", isOn: entry.isEnabled)
                .tint(.ptToggleOn)
                .labelsHidden()
                .scaleEffect(0.8)
                .onChange(of: entry.wrappedValue.isEnabled) { _, on in
                    if !on { ble.send(.scheduleClear) }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Add Schedule sheet

struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (String, String) -> Void

    @State private var selectedTime = Calendar.current.date(
        bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatLabel = "Everyday"
    @State private var action = "Open"

    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "hh:mm a"
        return f.string(from: selectedTime).uppercased()
    }

    var hhMM: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: selectedTime)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Big time display
                VStack(spacing: 4) {
                    // Hour : Minute AM
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(hour)
                            .font(Font.custom("Georgia", size: 52))
                            .foregroundColor(.ptText)
                        Text(":")
                            .font(Font.custom("Georgia", size: 52))
                            .foregroundColor(.ptTextMid)
                            .offset(y: -4)
                        Text(minute)
                            .font(Font.custom("Georgia", size: 52))
                            .foregroundColor(.ptText)
                        Text(ampm)
                            .font(Font.custom("Georgia", size: 18))
                            .foregroundColor(.ptTextMid)
                            .padding(.bottom, 6)
                    }

                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        #if os(iOS)
                        .datePickerStyle(.wheel)
                        #else
                        .datePickerStyle(.stepperField)
                        #endif
                        .labelsHidden()
                        .colorMultiply(.ptPink)
                        .frame(height: 120)
                        .clipped()
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(Color.ptCream)

                Divider().background(Color.ptDivider)

                // Options
                VStack(spacing: 0) {
                    optionRow(label: "Repeat") {
                        Menu {
                            ForEach(["Everyday","Weekdays","Weekends","Once"], id: \.self) { opt in
                                Button(opt) { repeatLabel = opt }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(repeatLabel).font(.ptBody).foregroundColor(.ptTextMid)
                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(.ptTextLight)
                            }
                        }
                    }

                    Divider().background(Color.ptDivider).padding(.leading, 20)

                    optionRow(label: "Action") {
                        Menu {
                            Button("Open")  { action = "Open" }
                            Button("Close") { action = "Close" }
                        } label: {
                            HStack(spacing: 4) {
                                Text(action).font(.ptBody).foregroundColor(.ptTextMid)
                                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundColor(.ptTextLight)
                            }
                        }
                    }
                }
                .background(Color.ptCream)

                Spacer()
            }
            .background(Color.ptCream.ignoresSafeArea())
            .navigationTitle("Add Schedule")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ptTextMid)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(hhMM, action)
                        dismiss()
                    }
                    .foregroundColor(.ptPinkDeep)
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    func optionRow<T: View>(label: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Text(label)
                .font(.ptBody)
                .foregroundColor(.ptText)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    var hour:   String { let f = DateFormatter(); f.dateFormat = "hh"; return f.string(from: selectedTime) }
    var minute: String { let f = DateFormatter(); f.dateFormat = "mm"; return f.string(from: selectedTime) }
    var ampm:   String { let f = DateFormatter(); f.dateFormat = "a";  return f.string(from: selectedTime).uppercased() }
}
