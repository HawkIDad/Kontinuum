<!-- NoteBytez20260917v2-EULA-Agreement.md -->
<!--
  User story to create the End User License Agreement.
-->
# User Story
As the Product Owner I want to define the End User License Agreement (EULA). This is a resticted license that allows the user to use the program for it's intended purposes - a note-taking app for people who want to be able to organize their notes for their own perosonal projects, at times sharing wiht others. The license agreement does not allow the user to reverese compile in any attempt to alter or reuse the code for other purposes.
The NoteBytez app does take advantage of other products and services to perform it's tasks - most notably Apple CloudKit services for both storing data that can then be synced across a users personal devices (iPhone, iPad, and/or Mac), as well as sharing notes with other users of the NoteBytez app.
NoteBytez is distributed exclusively through the Apple App Store as a paid monthly subscription, requires End Users to be at least 13 years old, and End Users retain ownership of the notes/content they create. KwickSync retains ownership of the App itself, and End Users have a 30-day window to opt out of the arbitration clause.

# Success Factors
1. The EULA will use the English language as its original source language.
2. The EULA will prefer common English over legalise.
    - Only using legal terms where necessary to ensure that the language will be upheld in a court of law.
    - Preferring short straight forward language to complex language that might be misunderstood.
3. The EULA will remove all liability from the company providing NoteBytez, KwickSync. 
4. The EULA will establish that KwickSync will not be liable for any data loss or corruption.
5. The EULA will limit damages to no more than 1 year of the monthly fees paid by the End User to have access to the Notebytez app. Access to NoteBytez is a paid monthly subscription (no free tier); this cap is expressed against subscription fees paid.
6. The EULA will state all claims will be resolved through arbitration.
    - The EULA will state that the arbitration location process will be performed in the Des Moines Metro Area in the State of Iowa, in the United States of America.
    - THe EULA will state that KwickSync will select an Arbitrator that is a standing member of the Iowa Academy of Mediators & Arbitrators.
    - The arbitrator conducts the arbitration under their own procedures; there is no formal administering body (e.g. no AAA/JAMS rules apply).
7. The EULA will state that the agreement adheres to and is bound by the laws of the State of Iowa, in the United States of America.
8. The EULA will restrict End Users from forming any class action suit to settle any claims, stating that each individual must adhere to the arbitration clause.
9. The EULA will require End Users to be at least 13 years old.
10. The EULA will state that End Users retain ownership of the notes/content they create; KwickSync receives only a limited license to store, sync, transmit, and (where the End User initiates it) share that content in order to operate the service.
11. The EULA will include Apple's required Minimum Terms for apps distributed via the App Store (Apple as a third-party beneficiary, Apple has no maintenance/support or warranty obligation, the license is limited to Apple-branded devices the End User owns/controls per the App Store's Usage Rules, and the End User's compliance representations regarding export control and not being a prohibited party).
12. On termination of the license (voluntary cancellation or breach-based termination by KwickSync), the App will continue to give the End User read-only access to and export of their existing Content for as long as it remains installed, with no forced deletion timeline — matching the app's existing, deliberate "never delete on lapse" design (Security design doc NoteBytez20260907v1-Security.md, resolutions G16/G17) and the fact that KwickSync never holds a copy of Content to delete in the first place. Resubscribing restores full functionality with no data loss.
13. The EULA will require End Users to indemnify, defend, and hold harmless KwickSync against claims arising from content the End User shares or from the End User's misuse of the sharing feature.
14. The EULA will summarize what data is collected/synced via CloudKit and will reference a separate Privacy Policy document as the authoritative source on data collection and use.
15. The EULA will state that KwickSync owns the App itself (its code, UI, and the "NoteBytez"/"KwickSync" names and logos) and that no license to KwickSync's own intellectual property is granted beyond the limited use license in Success Factor entry regarding the License Grant.
16. The EULA will include an Acceptable Use section prohibiting conduct beyond illegal/infringing content, including scraping or automating access to the App, attempting to disrupt or overload the service, impersonating another person, and harassing or abusing other users through the sharing feature.
17. The EULA will include a Feedback clause: suggestions or feedback End Users submit may be used by KwickSync without restriction or compensation to the End User.
18. The EULA will state that KwickSync may update, change, or discontinue features of the App at its discretion.
19. The EULA will include a Survival clause listing which sections (liability, indemnification, arbitration, governing law) remain in effect after termination.
20. The EULA will include the California Consumer Rights notice required by California Civil Code Section 1789.3 for End Users who are California residents.
21. The EULA will include a 30-day arbitration opt-out right: an End User may opt out of the binding arbitration and class-action waiver in Success Factor 6/8 by sending KwickSync written notice within 30 days of first accepting the EULA.
22. The EULA will include a Force Majeure clause excusing KwickSync's performance for events outside its reasonable control, including outages of Apple's CloudKit services.
23. The EULA will state that opting out of arbitration under Success Factor 21 has no effect on the End User's subscription, access to the App, or any other rights or obligations under the Agreement — KwickSync will not suspend access, terminate the account, or withhold/refund fees because an End User exercised the opt-out right. This avoids the "illusory opt-out" risk that can be used to invalidate the arbitration clause in Success Factor 6/8.
24. Because the Data Use Policy confirms NoteBytez is distributed worldwide (including the EU/UK), the EULA will include a consumer-protection carve-out: for an End User located in a jurisdiction whose consumer-protection law does not permit mandatory pre-dispute arbitration, a class-action waiver, or the chosen Iowa governing law to be enforced against a consumer, that jurisdiction's mandatory consumer-protection law applies instead, to the extent required by that law.
25. The EULA's Eligibility section will note that, in addition to the 13-year-old minimum, End Users in the EU/UK must also meet their own country's GDPR/UK GDPR digital consent age (which can be as high as 16), cross-referencing the Data Use Policy's Children's Privacy section for detail.
26. The EULA's Subscription and Payment section will describe both monthly and annual paid subscription options (rather than monthly only), generalize the renewal/cancellation language to apply to either billing cadence, and note that switching between plans is handled through the End User's Apple ID subscription settings per Apple's own rules.
27. The EULA's Termination section (and the Data Use Policy's Data Retention section) will describe App and paywall behavior that actually exists in the codebase: the App always keeps a lapsed End User's existing Content available for read-only browsing and export (App files: BlockedView.swift, PaywallView.swift, ExportDAL.swift), and the App's own Terms of Use / Privacy Policy links will point to the real bundled EULA and Data Use Policy documents rather than placeholder URLs.

