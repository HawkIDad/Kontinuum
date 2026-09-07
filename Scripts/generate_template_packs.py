#!/usr/bin/env python3
"""Authoring source for the bundled Template Packs.

Run to regenerate Kontinuum/Resources/TemplatePacks.json:

    python3 Scripts/generate_template_packs.py

Per Kontinuum20260824v1-Templates.md (Phases 2-3). English-only for now; when multi-language
support resumes, the literal strings here become String Catalog keys resolved at add-time.

Canonical fields (must use these exact spellings / types where the concept applies):
    Status (text) · Owner (text) · Priority (text) · Start Date (date) · Due Date (date)
    Stakeholders (list) · Reviewed (checkbox)
"""

import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "Kontinuum" / "Resources" / "TemplatePacks.json"


def f(name, kind="text", default=""):
    return {"name": name, "valueType": kind, "defaultValue": default}


def t(name, fields, body):
    return {"name": name, "fields": fields, "bodyTemplate": body.strip("\n") + "\n"}


def pack(pack_id, version, category, display_name, summary, roles, templates, note=None):
    return {
        "packId": pack_id, "version": version, "category": category,
        "displayName": display_name, "summary": summary, "note": note,
        "roleAliases": roles, "templates": templates,
    }


PACKS = []

# ── Essentials ────────────────────────────────────────────────────────────────
PACKS.append(pack(
    "common-km-essentials", 1, "Essentials", "Common / KM Essentials",
    "Universal notes every knowledge worker needs — meetings, decisions, one-on-ones, reviews.",
    [],
    [
        t("Meeting Notes",
          [f("Status", "text", "Scheduled"), f("Owner"), f("Stakeholders", "list")],
          """
# Meeting Notes

**Date:**
**Attendees:**

## Agenda

-

## Discussion

-

## Decisions

-

## Action Items

- [ ]
- [ ]
"""),
        t("One-on-One",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# One-on-One

**With:**
**Date:**

## Since last time

-

## Their topics

-

## My topics

-

## Growth / feedback

-

## Action Items

- [ ]
"""),
        t("Decision Record",
          [f("Status", "text", "Proposed"), f("Owner"), f("Due Date", "date")],
          """
# Decision Record

## Context

What situation forces a decision now.

## Options considered

1.
2.

## Decision

What we are doing, and why.

## Consequences

- Trade-offs accepted:
- Follow-ups:

## Action Items

- [ ] Communicate the decision
"""),
        t("Status Update",
          [f("Status", "text", "On Track"), f("Owner"), f("Due Date", "date")],
          """
# Status Update

**Period:**

## Summary

One or two sentences on where things stand.

## Progress

-

## Risks / blockers

-

## Next

-
"""),
        t("Retrospective",
          [f("Owner"), f("Stakeholders", "list")],
          """
# Retrospective

**Scope:**
**Date:**

## What went well

-

## What didn't

-

## What we'll change

-

## Action Items

- [ ]
"""),
        t("Weekly Review",
          [f("Reviewed", "checkbox", "false")],
          """
# Weekly Review

**Week of:**

## Wins

-

## Open loops

-

## Did not get to

-

## Focus for next week

- [ ]
- [ ]
- [ ]
"""),
    ],
))

# ── Engineering & Data ───────────────────────────────────────────────────────
PACKS.append(pack(
    "software-engineering", 1, "Engineering & Data", "Software Engineering",
    "Design docs, ADRs, runbooks, postmortems, and service notes.",
    ["Software Engineer"],
    [
        t("Design Doc",
          [f("Status", "text", "Draft"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Design Doc

## Problem

What we're solving and why now.

## Goals / non-goals

- Goals:
- Non-goals:

## Proposed design

## Alternatives considered

## Rollout & risks

## Action Items

- [ ] Circulate for review
- [ ] Record the decision as an ADR
"""),
        t("Architecture Decision Record",
          [f("Status", "text", "Proposed"), f("Owner")],
          """
# ADR: <short title>

## Status

Proposed

## Context

## Decision

## Consequences

- Positive:
- Negative:
"""),
        t("Runbook",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Runbook: <system / task>

## When to use this

## Preconditions

## Steps

1.
2.
3.

## Verification

## Rollback

## Escalation
"""),
        t("Incident Postmortem",
          [f("Status", "text", "Draft"), f("Owner"), f("Priority", "text", "High")],
          """
# Incident Postmortem

**Incident:**
**Date / duration:**
**Impact:**

## Timeline

-

## Root cause

## What went well

## What went poorly

## Action Items

- [ ] Preventive fix
- [ ] Detection improvement
- [ ] Follow-up review
"""),
        t("Service Overview",
          [f("Owner"), f("Status", "text", "Active")],
          """
# Service: <name>

## Purpose

## Interfaces

- Inbound:
- Outbound:

## Dependencies

## Operational notes

- Dashboards:
- Alerts:
- On-call:
"""),
        t("Tech Spike",
          [f("Status", "text", "In Progress"), f("Owner"), f("Due Date", "date")],
          """
# Spike: <question>

## Question

## Time box

## Findings

## Recommendation

## Action Items

- [ ] Share findings
"""),
    ],
))

PACKS.append(pack(
    "technical-writing", 1, "Engineering & Data", "Technical Writing",
    "Doc plans, how-to guides, reference topics, release notes, and doc reviews.",
    ["Technical Writer"],
    [
        t("Doc Plan",
          [f("Status", "text", "Planning"), f("Owner"), f("Due Date", "date")],
          """
# Doc Plan: <feature / release>

## Audience

## Deliverables

- [ ] Topic:
- [ ] Topic:

## Sources & SMEs

## Timeline

## Open questions
"""),
        t("How-To Guide",
          [f("Status", "text", "Draft"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# How to <accomplish task>

## Before you begin

## Steps

1.
2.
3.

## Result

## Troubleshooting

## Related
"""),
        t("Reference Topic",
          [f("Status", "text", "Draft"), f("Owner")],
          """
# <API / setting / command>

## Summary

## Syntax / signature

## Parameters

| Name | Type | Description |
|---|---|---|
|  |  |  |

## Examples

## Notes
"""),
        t("Release Notes",
          [f("Status", "text", "Draft"), f("Owner"), f("Due Date", "date")],
          """
# Release Notes — <version>

## Highlights

-

## New

-

## Changed

-

## Fixed

-

## Known issues

-
"""),
        t("Style / Terminology Entry",
          [f("Reviewed", "checkbox", "false")],
          """
# Term: <term>

**Use:**
**Don't use:**
**Definition:**
**Example sentence:**
**Notes:**
"""),
        t("Doc Review",
          [f("Status", "text", "Open"), f("Owner"), f("Stakeholders", "list")],
          """
# Doc Review: <document>

## Scope

## Findings

| Location | Issue | Severity | Fix |
|---|---|---|---|
|  |  |  |  |

## Action Items

- [ ]
"""),
    ],
))

PACKS.append(pack(
    "data-architecture-governance", 1, "Engineering & Data", "Data Architecture & Governance",
    "Data domains, models, dictionary terms, quality rules, and stewardship.",
    ["Data Architect", "Data Governance Manager"],
    [
        t("Data Domain",
          [f("Owner"), f("Status", "text", "Active"), f("Stakeholders", "list")],
          """
# Data Domain: <name>

## Description

## Systems of record

## Key entities

## Stewards

## Policies that apply
"""),
        t("Data Model",
          [f("Status", "text", "Draft"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Data Model: <subject area>

## Entities

- **<Entity>** — description
  - Attributes:
  - Keys:

## Relationships

-

## Open questions
"""),
        t("Glossary Term",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Term: <business term>

**Definition:**
**Also known as:**
**Data element(s):**
**Owner / steward:**
**Allowed values / format:**
**Notes:**
"""),
        t("Data Quality Rule",
          [f("Status", "text", "Proposed"), f("Owner"), f("Priority", "text", "Medium")],
          """
# DQ Rule: <name>

## Applies to

Dataset / field:

## Rule

## Threshold

## Measurement

## On failure

## Action Items

- [ ] Implement check
- [ ] Assign remediation owner
"""),
        t("Steward Assignment",
          [f("Owner"), f("Start Date", "date")],
          """
# Steward Assignment

**Domain / dataset:**
**Steward:**
**Backup:**
**Responsibilities:**
**Review cadence:**
"""),
        t("Governance Issue",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "Medium"), f("Due Date", "date")],
          """
# Governance Issue: <title>

## Description

## Impact

## Proposed remediation

## Action Items

- [ ]
"""),
    ],
))

PACKS.append(pack(
    "knowledge-organization", 1, "Engineering & Data", "Knowledge Organization",
    "Taxonomies, content models, catalog items, retention schedules, and records series.",
    ["Information Architect", "Librarian", "Records Manager"],
    [
        t("Taxonomy Entry",
          [f("Owner"), f("Status", "text", "Draft"), f("Reviewed", "checkbox", "false")],
          """
# Taxonomy Entry: <term>

**Parent:**
**Definition (scope note):**
**Use for (synonyms):**
**Related terms:**
**Where used:**
"""),
        t("Content Model",
          [f("Status", "text", "Draft"), f("Owner")],
          """
# Content Model: <content type>

## Purpose

## Fields

| Field | Type | Required | Notes |
|---|---|---|---|
|  |  |  |  |

## Relationships

## Governance (who creates / approves)
"""),
        t("Catalog Item",
          [f("Owner"), f("Start Date", "date")],
          """
# Catalog Item

**Title:**
**Creator / author:**
**Identifier:**
**Format / medium:**
**Location:**
**Subjects / tags:**
**Description:**
"""),
        t("Retention Schedule",
          [f("Status", "text", "Active"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Retention Schedule: <records series>

**Description:**
**Retention period:**
**Trigger event:**
**Disposition:** (destroy / archive / transfer)
**Legal / regulatory basis:**
**Review date:**
"""),
        t("Records Series",
          [f("Owner"), f("Status", "text", "Active")],
          """
# Records Series: <name>

## Description

## Formats

## Volume / growth

## Access restrictions

## Applicable retention schedule
"""),
        t("Reference Query",
          [f("Status", "text", "Open"), f("Owner")],
          """
# Reference Query

**Requester:**
**Date:**
**Question:**

## Sources checked

-

## Answer provided

## Follow-up

- [ ]
"""),
    ],
))

# ── Product & Delivery ──────────────────────────────────────────────────────
PACKS.append(pack(
    "project-management", 1, "Product & Delivery", "Project Management",
    "Charters, status reports, risk and stakeholder registers, change requests, lessons learned.",
    ["Project Manager"],
    [
        t("Project Charter",
          [f("Status", "text", "Draft"), f("Owner"), f("Start Date", "date"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Project Charter: <name>

## Purpose / business case

## Objectives & success criteria

-

## Scope

- In:
- Out:

## Milestones

| Milestone | Target date |
|---|---|
|  |  |

## Team & stakeholders

## Assumptions & constraints

## Action Items

- [ ] Confirm sponsor sign-off
"""),
        t("Status Report",
          [f("Status", "text", "On Track"), f("Owner"), f("Due Date", "date")],
          """
# Status Report

**Reporting period:**
**Overall:** On Track / At Risk / Off Track

## Accomplishments

-

## Planned next period

-

## Risks / issues

-

## Decisions / help needed

-
"""),
        t("Risk Register Entry",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "Medium")],
          """
# Risk: <title>

**Probability:** Low / Medium / High
**Impact:** Low / Medium / High

## Description

## Mitigation

## Contingency

## Trigger / early warning

## Action Items

- [ ]
"""),
        t("Stakeholder Register Entry",
          [f("Owner")],
          """
# Stakeholder: <name / group>

**Role / interest:**
**Influence:** Low / Medium / High
**Support:** Blocker / Neutral / Champion
**Communication needs:**
**Notes:**
"""),
        t("Change Request",
          [f("Status", "text", "Submitted"), f("Owner"), f("Priority", "text", "Medium"), f("Due Date", "date")],
          """
# Change Request: <title>

## Description of change

## Reason

## Impact (scope / schedule / cost / risk)

## Decision

## Action Items

- [ ]
"""),
        t("Lessons Learned",
          [f("Owner"), f("Stakeholders", "list")],
          """
# Lessons Learned: <project / phase>

## What worked

-

## What didn't

-

## Recommendations for next time

-
"""),
    ],
))

PACKS.append(pack(
    "product-management", 1, "Product & Delivery", "Product Management",
    "PRDs, requirements and user stories, discovery interviews, competitor profiles, roadmap themes.",
    ["Product Manager", "Business Analyst"],
    [
        t("Product Requirements (PRD)",
          [f("Status", "text", "Draft"), f("Owner"), f("Priority", "text", "Medium"), f("Reviewed", "checkbox", "false")],
          """
# PRD: <feature>

## Problem & opportunity

## Target users

## Goals & success metrics

-

## Requirements

- Must:
- Should:
- Won't (this release):

## UX notes / flows

## Open questions

## Action Items

- [ ] Review with engineering
- [ ] Review with design
"""),
        t("User Story",
          [f("Status", "text", "Backlog"), f("Owner"), f("Priority", "text", "Medium")],
          """
# <As a …, I want …, so that …>

## Acceptance criteria

- [ ] Given / when / then
- [ ]

## Notes / edge cases

## Out of scope
"""),
        t("Discovery Interview",
          [f("Owner"), f("Start Date", "date")],
          """
# Discovery Interview

**Participant (role):**
**Date:**

## Context / current workflow

## Pain points

-

## Quotes

>

## Signals / hypotheses

## Follow-up

- [ ]
"""),
        t("Competitor Profile",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Competitor: <name>

## Positioning

## Strengths

## Weaknesses

## Pricing

## Where we win / lose

## Watch list
"""),
        t("Roadmap Theme",
          [f("Status", "text", "Proposed"), f("Owner"), f("Due Date", "date")],
          """
# Roadmap Theme: <name>

## Outcome we're pursuing

## Why now

## Bets / initiatives

-

## Success measures

## Dependencies
"""),
        t("Requirements / Process Doc",
          [f("Status", "text", "Draft"), f("Owner"), f("Stakeholders", "list")],
          """
# Requirements: <process / capability>

## Current state

## Desired state

## Functional requirements

-

## Non-functional requirements

-

## Assumptions & constraints

## Action Items

- [ ]
"""),
    ],
))

PACKS.append(pack(
    "operations-service-management", 1, "Product & Delivery", "Operations & Service Management",
    "SOPs, incidents, problem records, change requests, service/asset notes, and metric reviews.",
    ["Operations Manager", "IT Service Desk Analyst"],
    [
        t("Standard Operating Procedure",
          [f("Status", "text", "Active"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# SOP: <process>

## Purpose & scope

## Roles

## Procedure

1.
2.
3.

## Exceptions

## Records produced

## Review cadence
"""),
        t("Incident Ticket",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "High")],
          """
# Incident: <short description>

**Reported by / when:**
**Affected service / users:**

## Symptoms

## Timeline

-

## Resolution / workaround

## Follow-up (link problem record if root cause unknown)

## Action Items

- [ ]
"""),
        t("Problem Record",
          [f("Status", "text", "Under Investigation"), f("Owner"), f("Priority", "text", "Medium")],
          """
# Problem: <title>

## Related incidents

-

## Investigation

## Root cause

## Permanent fix

## Action Items

- [ ]
"""),
        t("Change Request",
          [f("Status", "text", "Submitted"), f("Owner"), f("Priority", "text", "Medium"), f("Due Date", "date")],
          """
# Change Request: <title>

## What is changing

## Reason / benefit

## Risk & backout plan

## Implementation window

## Approvals

## Action Items

- [ ]
"""),
        t("Service / Asset",
          [f("Owner"), f("Status", "text", "Active")],
          """
# Service / Asset: <name>

**Type:**
**Owner / support group:**
**Environment / location:**
**Dependencies:**
**Support hours / SLA:**
**Notes:**
"""),
        t("Metric Review",
          [f("Owner"), f("Due Date", "date")],
          """
# Metric Review

**Period:**

## KPIs

| Metric | Target | Actual | Trend |
|---|---|---|---|
|  |  |  |  |

## Observations

## Action Items

- [ ]
"""),
    ],
))

PACKS.append(pack(
    "consulting-research", 1, "Product & Delivery", "Consulting & Research",
    "Engagement briefs, client profiles, interviews, findings & recommendations, workshops, research questions.",
    ["Management Consultant", "Research Analyst"],
    [
        t("Engagement Brief",
          [f("Status", "text", "Active"), f("Owner"), f("Start Date", "date"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Engagement: <client / name>

## Objective

## Scope & deliverables

-

## Approach

## Team & roles

## Timeline / milestones

## Risks

## Action Items

- [ ] Confirm scope with sponsor
"""),
        t("Client Profile",
          [f("Owner")],
          """
# Client: <organization>

## Overview

## Key contacts

| Name | Role | Notes |
|---|---|---|
|  |  |  |

## History with us

## Strategic context

## Sensitivities
"""),
        t("Interview Notes",
          [f("Owner"), f("Start Date", "date")],
          """
# Interview

**Interviewee (role):**
**Date:**

## Topics

-

## Key points

-

## Notable quotes

>

## Implications / hypotheses

## Follow-up

- [ ]
"""),
        t("Findings & Recommendations",
          [f("Status", "text", "Draft"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Findings & Recommendations

## Executive summary

## Findings

1.
2.

## Recommendations

| # | Recommendation | Impact | Effort | Owner |
|---|---|---|---|---|
|  |  |  |  |  |

## Next steps

- [ ]
"""),
        t("Workshop Plan",
          [f("Owner"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Workshop: <topic>

## Objective & outcomes

## Participants

## Agenda

| Time | Segment | Facilitator |
|---|---|---|
|  |  |  |

## Materials / prework

## Parking lot
"""),
        t("Research Question",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "Medium")],
          """
# Research Question

## Question

## Why it matters

## Hypothesis

## Method / sources

## Findings

## Answer / confidence

## Action Items

- [ ]
"""),
    ],
))

# ── Go-to-Market ───────────────────────────────────────────────────────────
PACKS.append(pack(
    "customer-success", 1, "Go-to-Market", "Customer Success",
    "Account health, business reviews, onboarding plans, escalations, and renewal risk.",
    ["Customer Success Manager"],
    [
        t("Account Health",
          [f("Status", "text", "Green"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Account Health: <customer>

**Overall:** Green / Yellow / Red
**ARR / plan:**
**Renewal date:**

## Usage & adoption

## Relationship (champions, detractors)

## Open issues

## Opportunities (expansion)

## Action Items

- [ ]
"""),
        t("Business Review (QBR)",
          [f("Owner"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Business Review

**Customer:**
**Period:**

## Goals set last time

## Results & value delivered

## Roadmap / what's next

## Risks & asks

## Action Items

- [ ]
"""),
        t("Onboarding Plan",
          [f("Status", "text", "In Progress"), f("Owner"), f("Start Date", "date"), f("Due Date", "date")],
          """
# Onboarding Plan: <customer>

## Success criteria (first value by …)

## Milestones

- [ ] Kickoff
- [ ] Configuration complete
- [ ] First workflow live
- [ ] Team trained
- [ ] Go-live review

## Stakeholders

## Risks
"""),
        t("Support Escalation",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "High")],
          """
# Escalation: <summary>

**Customer:**
**Raised:**
**Impact:**

## Background

## Current state

## Path to resolution

## Action Items

- [ ]
"""),
        t("Renewal / Churn Risk",
          [f("Status", "text", "At Risk"), f("Owner"), f("Due Date", "date")],
          """
# Renewal: <customer>

**Renewal date:**
**Risk level:** Low / Medium / High

## Risk drivers

## Value story / proof points

## Mitigation plan

## Action Items

- [ ]
"""),
    ],
))

PACKS.append(pack(
    "sales", 1, "Go-to-Market", "Sales",
    "Opportunities, account plans, discovery calls, proposals, and competitor battlecards.",
    ["Sales Specialist"],
    [
        t("Opportunity",
          [f("Status", "text", "Qualifying"), f("Owner"), f("Priority", "text", "Medium"), f("Due Date", "date")],
          """
# Opportunity: <account — deal>

**Stage:**
**Amount:**
**Close date:**

## Pain / compelling event

## Decision process & criteria

## Champion / economic buyer

## Competition

## Next step

## Action Items

- [ ]
"""),
        t("Account Plan",
          [f("Owner"), f("Stakeholders", "list")],
          """
# Account Plan: <account>

## Overview & whitespace

## Buying centers / contacts

| Name | Role | Disposition |
|---|---|---|
|  |  |  |

## Strategy for the year

## Risks
"""),
        t("Discovery Call",
          [f("Owner"), f("Start Date", "date")],
          """
# Discovery Call

**Account / contact:**
**Date:**

## Current situation

## Pain & impact

## Desired outcome

## Timeline & budget signals

## Next step agreed

## Action Items

- [ ]
"""),
        t("Proposal Outline",
          [f("Status", "text", "Draft"), f("Owner"), f("Due Date", "date")],
          """
# Proposal: <account>

## Understanding of needs

## Recommended solution

## Scope & deliverables

## Pricing summary

## Timeline

## Terms / assumptions
"""),
        t("Competitor Battlecard",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Battlecard: <competitor>

## Their pitch

## Where we win

## Where they win

## Landmines to set

## Objection handling

| Objection | Response |
|---|---|
|  |  |
"""),
    ],
))

PACKS.append(pack(
    "marketing", 1, "Go-to-Market", "Marketing",
    "Campaign briefs, content calendar entries, personas, channel plans, and launch plans.",
    ["Marketing Specialist"],
    [
        t("Campaign Brief",
          [f("Status", "text", "Draft"), f("Owner"), f("Start Date", "date"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Campaign Brief: <name>

## Objective & KPI

## Audience

## Key message & proof points

## Channels & tactics

-

## Budget

## Timeline

## Action Items

- [ ]
"""),
        t("Content Calendar Entry",
          [f("Status", "text", "Idea"), f("Owner"), f("Due Date", "date")],
          """
# Content: <working title>

**Format:**
**Channel:**
**Publish date:**

## Angle / hook

## Key points

-

## CTA

## Assets needed

- [ ]
"""),
        t("Persona",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Persona: <name>

**Role / segment:**

## Goals

## Frustrations

## Where they get information

## Buying triggers

## Objections

## Messaging that resonates
"""),
        t("Channel Plan",
          [f("Owner"), f("Status", "text", "Draft")],
          """
# Channel Plan: <channel>

## Role in the mix

## Audience & targeting

## Cadence & formats

## Budget & KPIs

## Experiments to run

- [ ]
"""),
        t("Launch Plan",
          [f("Status", "text", "Planning"), f("Owner"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Launch Plan: <product / feature>

## Positioning & messaging

## Launch tier

## Timeline (T-minus)

| When | Activity | Owner |
|---|---|---|
|  |  |  |

## Assets checklist

- [ ] Announcement
- [ ] Docs
- [ ] Sales enablement

## Success metrics
"""),
    ],
))

# ── People ────────────────────────────────────────────────────────────────
PACKS.append(pack(
    "people-ops-hr", 1, "People", "People Ops (HR)",
    "Job descriptions, candidates, interview debriefs, onboarding plans, policies, and headcount planning.",
    ["Human Resources Specialist", "Human Resources Manager"],
    [
        t("Job Description",
          [f("Status", "text", "Draft"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Job Description: <title>

**Team / manager:**
**Level:**
**Location / type:**

## Mission of the role

## Responsibilities

-

## Requirements

- Must:
- Nice to have:

## Interview loop
"""),
        t("Candidate",
          [f("Status", "text", "Screening"), f("Owner"), f("Priority", "text", "Medium")],
          """
# Candidate: <name>

**Role:**
**Source:**

## Snapshot

## Screen notes

## Loop feedback

| Interviewer | Signal | Notes |
|---|---|---|
|  |  |  |

## Decision

## Action Items

- [ ]
"""),
        t("Interview Debrief",
          [f("Owner"), f("Start Date", "date")],
          """
# Interview Debrief

**Candidate:**
**Role:**

## Recommendation

Strong Yes / Yes / No / Strong No

## Strengths

## Concerns

## Areas for others to probe
"""),
        t("Onboarding Plan",
          [f("Status", "text", "In Progress"), f("Owner"), f("Start Date", "date")],
          """
# Onboarding Plan: <new hire>

## Week 1

- [ ] Accounts & access
- [ ] Team intros
- [ ] First task

## 30 / 60 / 90 day goals

- 30:
- 60:
- 90:

## Buddy / manager check-ins
"""),
        t("Policy",
          [f("Status", "text", "Active"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Policy: <name>

## Purpose

## Scope (who it applies to)

## Policy

## Procedure

## Exceptions & approvals

## Effective date / review date
"""),
        t("Headcount Plan",
          [f("Owner"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Headcount Plan: <team / period>

## Current headcount

## Planned hires

| Role | Level | Target start | Justification |
|---|---|---|---|
|  |  |  |  |

## Backfills

## Budget impact
"""),
    ],
))

PACKS.append(pack(
    "learning-development", 1, "People", "Learning & Development",
    "Curricula, lesson plans, learning objectives, session notes, assessments, and needs analyses.",
    ["Learning and Development Specialist", "Corporate Trainer"],
    [
        t("Course / Curriculum",
          [f("Status", "text", "Draft"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Course: <title>

## Audience & prerequisites

## Learning outcomes

- By the end, learners can:

## Modules

| # | Module | Duration | Method |
|---|---|---|---|
|  |  |  |  |

## Assessment approach

## Materials
"""),
        t("Lesson Plan",
          [f("Owner"), f("Due Date", "date")],
          """
# Lesson Plan: <topic>

**Duration:**
**Objective:**

## Opening (hook)

## Content & activities

| Time | Activity | Notes |
|---|---|---|
|  |  |  |

## Practice / check for understanding

## Close & next steps
"""),
        t("Learning Objective",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Learning Objective

**Statement (observable, measurable):**
**Bloom level:**
**How it's assessed:**
**Maps to (competency / course):**
"""),
        t("Session Delivery Notes",
          [f("Owner"), f("Start Date", "date")],
          """
# Session Delivery Notes

**Course / cohort:**
**Date:**
**Attendance:**

## What went well

## What to adjust

## Learner questions to follow up

- [ ]
"""),
        t("Assessment",
          [f("Status", "text", "Draft"), f("Owner")],
          """
# Assessment: <name>

## Purpose (formative / summative)

## Objectives covered

## Items

1.
2.

## Scoring / rubric

## Pass criteria
"""),
        t("Training Needs Analysis",
          [f("Owner"), f("Due Date", "date"), f("Stakeholders", "list")],
          """
# Training Needs Analysis: <audience>

## Business driver

## Current vs. required capability

## Gaps

-

## Recommended interventions

## Action Items

- [ ]
"""),
    ],
))

# ── Governance & Compliance ────────────────────────────────────────────────
PACKS.append(pack(
    "legal-operations", 1, "Governance & Compliance", "Legal Operations",
    "Matters, contract summaries, outside counsel, policies, compliance obligations, and approvals.",
    ["Legal Operations Specialist"],
    [
        t("Matter",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "Medium"), f("Due Date", "date")],
          """
# Matter: <name>

**Type:**
**Business sponsor:**
**Outside counsel:**

## Summary

## Key dates / deadlines

## Risk & exposure

## Budget / spend

## Action Items

- [ ]
"""),
        t("Contract Summary",
          [f("Status", "text", "In Review"), f("Owner"), f("Start Date", "date"), f("Due Date", "date")],
          """
# Contract Summary

**Counterparty:**
**Type:**
**Effective / expiry:**
**Renewal / notice:**

## Key terms

- Payment:
- Liability / indemnity:
- Termination:
- IP / confidentiality:

## Deviations from standard

## Action Items

- [ ]
"""),
        t("Outside Counsel / Vendor",
          [f("Owner"), f("Status", "text", "Active")],
          """
# Outside Counsel / Vendor: <firm>

**Practice areas:**
**Primary contact:**
**Rates / arrangement:**
**Engagement letter on file:** yes / no

## Performance notes
"""),
        t("Policy",
          [f("Status", "text", "Active"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Policy: <name>

## Purpose

## Scope

## Requirements

## Roles & responsibilities

## Effective / review date
"""),
        t("Compliance Obligation",
          [f("Status", "text", "Tracked"), f("Owner"), f("Due Date", "date"), f("Priority", "text", "Medium")],
          """
# Compliance Obligation: <regulation / requirement>

## What it requires

## How we comply (controls)

## Evidence / records

## Gaps

## Action Items

- [ ]
"""),
        t("Approval Log",
          [f("Owner")],
          """
# Approval Log: <item>

| Date | Approver | Decision | Notes |
|---|---|---|---|
|  |  |  |  |
"""),
    ],
))

PACKS.append(pack(
    "healthcare-administration", 1, "Governance & Compliance", "Healthcare Administration",
    "Administrative policies, accreditation items, department notes, vendors, safety reports, and committees.",
    ["Healthcare Administrator"],
    [
        t("Policy & Procedure",
          [f("Status", "text", "Active"), f("Owner"), f("Reviewed", "checkbox", "false"), f("Due Date", "date")],
          """
# Policy & Procedure: <name>

## Purpose

## Scope (departments / roles)

## Policy statement

## Procedure

1.
2.

## References / regulatory basis

## Approval / next review date
"""),
        t("Accreditation Item",
          [f("Status", "text", "In Progress"), f("Owner"), f("Priority", "text", "High"), f("Due Date", "date")],
          """
# Accreditation Item: <standard / element>

## Requirement

## Current compliance status

## Evidence / documentation

## Gaps & corrective actions

## Action Items

- [ ]
"""),
        t("Department / Unit",
          [f("Owner"), f("Status", "text", "Active")],
          """
# Department / Unit: <name>

**Manager:**
**Staffing model:**
**Key services:**
**Hours of operation:**

## Current priorities

## Notes
"""),
        t("Vendor / Contract",
          [f("Status", "text", "Active"), f("Owner"), f("Start Date", "date"), f("Due Date", "date")],
          """
# Vendor / Contract: <vendor>

**Service:**
**Term / renewal:**
**Cost:**
**BAA on file:** yes / no

## Performance / SLA notes

## Action Items

- [ ]
"""),
        t("Incident / Safety Report",
          [f("Status", "text", "Open"), f("Owner"), f("Priority", "text", "High")],
          """
# Incident / Safety Report

**Date / location:**
**Type:** (no patient identifiers in this note)

## Description

## Immediate actions taken

## Contributing factors

## Corrective / preventive actions

## Action Items

- [ ]
"""),
        t("Committee Meeting Notes",
          [f("Owner"), f("Stakeholders", "list")],
          """
# Committee Meeting Notes

**Committee:**
**Date / attendees:**

## Agenda

-

## Discussion & decisions

-

## Action Items

- [ ]
"""),
    ],
    note="Administrative use only — policies, credentialing, committees, compliance, vendors. Not a store for patient health information (PHI) or clinical records.",
))

# ── Food & Hospitality ──────────────────────────────────────────────────
PACKS.append(pack(
    "culinary-food-craft", 1, "Food & Hospitality", "Culinary & Food Craft",
    "Recipes, menus, prep lists, production batches, tastings, and supplier notes.",
    ["Chef", "Confectioner", "Chocolatier"],
    [
        t("Recipe",
          [f("Status", "text", "Testing"), f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Recipe: <name>

**Yield / portions:**
**Prep / cook time:**
**Allergens:**

## Ingredients

| Ingredient | Quantity | Notes |
|---|---|---|
|  |  |  |

## Method

1.
2.
3.

## Finishing / plating

## Costing

- Batch cost:
- Cost per portion:
- Target price / margin:

## Notes & variations
"""),
        t("Menu",
          [f("Status", "text", "Draft"), f("Owner"), f("Start Date", "date"), f("Stakeholders", "list")],
          """
# Menu: <service / event>

**Date / service:**
**Covers:**

## Courses

| Course | Dish | Recipe link | Price |
|---|---|---|---|
|  |  |  |  |

## Dietary coverage

- Vegetarian / vegan:
- Gluten-free:
- Nut-free:

## Costing summary

- Food cost %:
- Notes:

## Action Items

- [ ] Confirm ingredient availability
- [ ] Brief the team
"""),
        t("Prep List",
          [f("Owner"), f("Due Date", "date")],
          """
# Prep List: <service / date>

## Larder / cold

- [ ]
- [ ]

## Hot / sauces

- [ ]
- [ ]

## Pastry / bake

- [ ]

## Pass / assembly

- [ ]

## Order / receiving

- [ ]
"""),
        t("Production Batch",
          [f("Status", "text", "In Progress"), f("Owner"), f("Start Date", "date")],
          """
# Production Batch: <product>

**Recipe / version:**
**Batch size (target):**

## Parameters

- Temper / cook temp:
- Time:
- Humidity / conditions:

## Quality checks

- [ ] Appearance / gloss / set
- [ ] Texture / snap
- [ ] Flavour
- [ ] Weight / count per unit

## Results

- Yield (actual vs target):
- Rework / waste:
- Notes for next batch:
"""),
        t("Tasting / QC Note",
          [f("Reviewed", "checkbox", "false"), f("Owner")],
          """
# Tasting / QC Note

**Item / batch:**
**Date:**

## Appearance

## Aroma

## Texture / mouthfeel

## Flavour

## Verdict

Pass / adjust / reject

## Adjustments for next time

-
"""),
        t("Ingredient & Supplier",
          [f("Status", "text", "Approved"), f("Owner")],
          """
# Ingredient & Supplier: <ingredient>

**Product / grade:**
**Supplier:**
**Pack size / unit cost:**
**Lead time:**
**Allergens:**
**Storage:**

## Approved substitutes

-

## Notes (seasonality, quality history)
"""),
    ],
))

# ── Personal & Creative (the migrated starter packs) ──────────────────────
PACKS.append(pack(
    "fiction-writing", 1, "Personal & Creative", "Fiction Writing",
    "Characters, locations, and scenes for a novel or series.",
    [],
    [
        t("Character",
          [f("Species"), f("Homeworld"), f("Affiliation"), f("Status", "text", "Alive"), f("Alive", "checkbox", "true")],
          """
# <Character name>

## One-line

## Appearance

## Voice & mannerisms

## Wants vs. needs

## Backstory

## Relationships

## Arc across the story
"""),
        t("Location",
          [f("Region"), f("Description")],
          """
# <Location name>

## Sensory snapshot

## History

## Who is here, and why it matters

## Scenes set here
"""),
        t("Scene",
          [f("Status", "text", "Drafting"), f("Priority", "text", "Medium")],
          """
# Scene: <slug>

**POV:**
**Location:**
**Time:**

## Goal (whose, and what)

## Conflict / turn

## Outcome / new situation

## Notes / continuity
"""),
    ],
))

PACKS.append(pack(
    "wedding-planning", 1, "Personal & Creative", "Wedding Planning",
    "Vendors, guests, and the day-of timeline.",
    [],
    [
        t("Vendor",
          [f("Category"), f("Contact Email"), f("Booked", "checkbox", "false"), f("Due Date", "date")],
          """
# Vendor: <name>

**Category:**
**Phone / email:**
**Quote:**
**Deposit paid:** yes / no

## What's included

## Questions to ask

## Action Items

- [ ]
"""),
        t("Guest",
          [f("RSVP", "checkbox", "false"), f("Plus One", "checkbox", "false")],
          """
# Guest: <name>

**Side:**
**Invitation sent:** yes / no
**RSVP:** yes / no / pending
**Meal choice:**
**Dietary needs:**
**Table:**
**Notes:**
"""),
        t("Day-Of Timeline",
          [f("Owner")],
          """
# Day-Of Timeline

| Time | What | Who | Location |
|---|---|---|---|
|  |  |  |  |

## Key contacts

## Contingencies (weather, delays)
"""),
    ],
))

PACKS.append(pack(
    "photography-client-work", 1, "Personal & Creative", "Photography Client Work",
    "Clients, shoot locations, and shot lists.",
    [],
    [
        t("Client",
          [f("Shoot Date", "date"), f("Package Type"), f("Status", "text", "Inquiry")],
          """
# Client: <name>

**Contact:**
**Occasion:**
**Package:**
**Balance due:**

## Preferences & must-have shots

## Logistics

## Action Items

- [ ] Send contract
- [ ] Confirm timeline
"""),
        t("Shoot Location",
          [f("Address")],
          """
# Shoot Location: <name>

**Address:**
**Permit needed:** yes / no
**Best light / time:**
**Parking / access:**

## Backup location

## Notes
"""),
        t("Shot List",
          [f("Owner"), f("Reviewed", "checkbox", "false")],
          """
# Shot List: <session>

## Must-have

- [ ]
- [ ]

## Nice-to-have

- [ ]

## Group shots

- [ ]
"""),
    ],
))


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(PACKS, indent=2, ensure_ascii=False) + "\n")
    print(f"wrote {len(PACKS)} packs, {sum(len(p['templates']) for p in PACKS)} templates -> {OUT}")


if __name__ == "__main__":
    main()
