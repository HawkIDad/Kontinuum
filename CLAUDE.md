<!-- CLAUDE.md -->
- Ignore markdown files beginning with 'z_'
- Be concise - assume I'm a senior level developer and do not need detailed explanations on what I've asked you to do. When directed, show additional detail.

1. Think Before Coding
    - Don't assume. Don't hide confusion. Surface tradeoffs.
    - Before implementing:
        - State your assumptions explicitly. If uncertain, ask.
        - If multiple interpretations exist, present them - don't pick silently.
        - If a simpler approach exists, say so. Push back when warranted.
        - If something is unclear, stop. Name what's confusing. Ask.

2. Simplicity First
    - Minimum code that solves the problem. Nothing speculative.
        - No features beyond what was asked.
        - No abstractions for single-use code.
        - No "flexibility" or "configurability" that wasn't requested.
        - No error handling for impossible scenarios.
    - If you write 200 lines and it could be 50, rewrite it.
    - Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

3. Surgical Changes
    - Touch only what you must. Clean up only your own mess.
        - Read the the entire function/method so you don't reproduce functionalilty already existing in other chunks of code. 
    - When editing existing code:
        - Don't "improve" adjacent code, comments, or formatting.
        - Don't refactor things that aren't broken.
        - Match existing style, even if you'd do it differently.
    - If you notice unrelated dead code, mention it - don't delete it. When asked, comment it out.
    - When your changes create orphans:
        - Remove imports/variables/functions that YOUR changes made unused.
        - Don't remove pre-existing dead code unless asked. When asked, comment it out.
        - The test: Every changed line should trace directly to the user's request.

4. Goal-Driven Execution
    - Define success criteria. Loop until verified. If you have to try more than 3 times, stop and ask.
    - Transform tasks into verifiable goals:
        - "Add validation" → "Write tests for invalid inputs, then make them pass"
        - "Fix the bug" → "Write a test that reproduces it, then make it pass"
        - "Refactor X" → "Ensure tests pass before and after"
    - For multi-step tasks, state a brief plan:
        1. [Step] → verify: [check]
        2. [Step] → verify: [check]
        3. [Step] → verify: [check]
    
5. Use Apple and the Swift Community best practices when creating or updating code.
    - Clean Code principles - keep functions short, comment wisely. 
    - Avoid Forced Unwrapping - utilize optional binding or nil coalescing.
    - Code Organization - use extensions.
    - Memory Management - use weak references.
    - Leverage Swifts Standard Library - where possible use Swift's Standard Library - no reinventing the wheel.
      - If using the Swift Standard Library is not possible and you need a 3rd party framework, library, or tool
        - Select open source frameworks, libraries, or tools that are unencumbered and allow me to use them without restriction.
    - User Input - validate user input.
    - Naming convention - Classes/Enums/Models: CamelCase
    - Naming convention - Class Methods/Functions: lowerCamelCase.
    - Naming convention - Parameters: lowerCamelCase.
    - Variables
        - use lowerCamelCase convention.
        - user plural names for collections.
        - use meaningful variable names and avoid single letter names
        - avoid global variables.
        - prefix booleans - is, has, can, or should

6. Security 
    - user secure protocols to encrypt data in transit.
    - encrypt sensitive data when stored.

7. Testing 
    - implement unit tests - 100% code coverage.
    - implement integration tests.
    - adopt test driven development.

8. Debugging 
    - Verification - before attempting to fix a bug, write a test that reliably reproduces the bug. Only when the test passes, is the bug fixed.
    - Use a logging framework like OSLog.Logger to log important events and assist with debugging.

9. Architecture
    - Use MVVM (Model-View-ViewModel) as the design pattern.
        - Models will be stored in the {application}/models folder.
            - Models will have a data access layer (DAL) stored in {application}/dal folder.
        - View models will be stored in the {application}/viewModels folder.
        - Views will be stored in the {application}/views folder.
            - Views for a given model will be stored in {application}/views/{model name} folder.
    - Use CloudKit container for data storage: iCloud.com.g9Consulting.Kontinuum
        - CloudKit requires all model variables to be optional.
        - CloudKit does not allow @Attribute(.unique).
    - Models
    -   Models will have a declared id - {lowerCamelCase table name}Id - see below example:
        '''
        @Model
        final class StellarType: Codable, Identifiable {

            var stellarTypeId: UUID?  = UUID()
            var id: UUID { return self.stellarTypeId! }
        
        }
        '''

10. Views
    - All views will use {application}/docs/styleGuide.md as the base reference for design guidelines.

11. Copyright Notice
    - All .swift files genereated to support SwiftRPT will have a copyright notice placed in the file: // © Copyright, 2026 David L. Collison, All Rights Reserved.
        - Exceptions:
            - Swift standard control files:
                - Package.swift
