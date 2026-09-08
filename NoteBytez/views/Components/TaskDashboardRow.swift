// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskDashboardRow.swift
//  Kontinuum
//

import SwiftUI

/// Checkbox + task text + due-date/priority/recurrence indicators + source note, per
/// docs/styleGuide.md.
struct TaskDashboardRow: View {

    let dashboardTask: TaskDashboardViewModel.DashboardTask
    let onToggle: () -> Void

    private var task: TaskItem { dashboardTask.task }
    private var isDone: Bool { task.isDone ?? false }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            TaskCheckbox(label: task.content ?? "", isDone: isDone, action: onToggle)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.content ?? "")
                    .strikethrough(isDone)
                    .foregroundStyle(isDone ? .secondary : .primary)

                HStack(spacing: 10) {
                    Label(dashboardTask.documentTitle, systemImage: "doc.text")

                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }

                    if let priority = task.priority {
                        Label("P\(priority)", systemImage: "flag.fill")
                            .foregroundStyle(.orange)
                    }

                    if let rawRule = task.recurrenceRule, let rule = RecurrenceRule(rawValue: rawRule) {
                        RecurrenceControl(rule: rule)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
