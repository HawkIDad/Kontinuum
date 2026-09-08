// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskParserTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct TaskParserTests {

    @Test func matchDetectsAnOpenTask() {
        let match = TaskParser.match(in: "- [ ] Buy milk")
        #expect(match?.isDone == false)
        #expect(match?.text == "Buy milk")
    }

    @Test func matchDetectsADoneTask() {
        let match = TaskParser.match(in: "- [x] Buy milk")
        #expect(match?.isDone == true)
        #expect(match?.text == "Buy milk")
    }

    @Test func matchIsCaseInsensitiveForTheXMarker() {
        #expect(TaskParser.match(in: "- [X] Buy milk")?.isDone == true)
    }

    @Test func matchReturnsNilForAPlainListItem() {
        #expect(TaskParser.match(in: "- Buy milk") == nil)
    }

    @Test func matchReturnsNilForPlainText() {
        #expect(TaskParser.match(in: "Just a note") == nil)
    }

    @Test func matchAllowsAsteriskAndPlusListMarkers() {
        #expect(TaskParser.match(in: "* [ ] Buy milk")?.text == "Buy milk")
        #expect(TaskParser.match(in: "+ [ ] Buy milk")?.text == "Buy milk")
    }

    @Test func matchPreservesInlineWikilinksAndTagsInTaskText() {
        #expect(TaskParser.match(in: "- [ ] Review PR from [[Dana]] #standup")?.text == "Review PR from [[Dana]] #standup")
    }

    @Test func extractTasksFindsEveryCheckboxLineInOrder() {
        let content = "- [ ] First\nJust a note\n- [x] Second"
        let tasks = TaskParser.extractTasks(from: content)
        #expect(tasks.map { $0.text } == ["First", "Second"])
        #expect(tasks.map { $0.isDone } == [false, true])
    }

    @Test func extractTasksReturnsEmptyWithNoCheckboxLines() {
        #expect(TaskParser.extractTasks(from: "Just plain text.\n- A bullet.").isEmpty)
    }

    @Test func togglingFlipsAnOpenTaskToDone() {
        let result = TaskParser.toggling(taskIndex: 0, in: "- [ ] Buy milk")
        #expect(result == "- [x] Buy milk")
    }

    @Test func togglingFlipsADoneTaskToOpen() {
        let result = TaskParser.toggling(taskIndex: 0, in: "- [x] Buy milk")
        #expect(result == "- [ ] Buy milk")
    }

    @Test func togglingTargetsOnlyTheGivenIndexAmongMultipleTasks() {
        let content = "- [ ] First\n- [ ] Second\n- [ ] Third"
        let result = TaskParser.toggling(taskIndex: 1, in: content)
        #expect(result == "- [ ] First\n- [x] Second\n- [ ] Third")
    }

    @Test func togglingLeavesNonTaskLinesUntouched() {
        let content = "# Heading\n- [ ] Task\nSome prose."
        let result = TaskParser.toggling(taskIndex: 0, in: content)
        #expect(result == "# Heading\n- [x] Task\nSome prose.")
    }

    @Test func togglingIsNoOpWhenIndexIsOutOfRange() {
        let content = "- [ ] Only task"
        #expect(TaskParser.toggling(taskIndex: 5, in: content) == content)
        #expect(TaskParser.toggling(taskIndex: -1, in: content) == content)
    }

    @Test func togglingPreservesTaskTextExactly() {
        let content = "- [ ] Review PR from [[Dana]] #standup"
        let result = TaskParser.toggling(taskIndex: 0, in: content)
        #expect(result == "- [x] Review PR from [[Dana]] #standup")
    }

}
