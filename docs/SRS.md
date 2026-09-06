# Software Requirements Specification

# AI-Powered Upskilling Recommendation and Automation System for Students

## Document Information

| Field | Details |
|---|---|
| Project Title | AI-Powered Upskilling Recommendation and Automation System for Students |
| Project ID | 22 |
| Version | 1.0 |
| Status | Draft |

# 1. Introduction

## 1.1 Purpose

This Software Requirements Specification (SRS) defines the functional and non-functional requirements of the AI-Powered Upskilling Recommendation and Automation System for Students.

The purpose of the system is to help students understand their current skill set, identify suitable career paths, determine the skills they need to develop, and follow a structured learning roadmap.

The system uses student skill information to provide career recommendations. After a student selects a career path, the system compares the student's existing skills with the skills required for that career and identifies the missing skills.

Based on the identified skill gaps, the system generates a structured learning roadmap. Students can also track their progress as they complete the recommended skills.

This document serves as a reference for the development, testing, and evaluation of the system.

## 1.2 Intended Audience

This document is intended for:

- **Students:** Primary users of the system.
- **Development Team:** Team members responsible for designing and implementing the system.
- **Project Evaluators:** Faculty members evaluating the project.
- **Future Developers:** Developers who may maintain or extend the system.

## 1.3 Product Scope

The AI-Powered Upskilling Recommendation and Automation System for Students is a web-based application designed to assist students in planning their skill development.

The system allows students to:

- Create an account and log in.
- Create and manage a student profile.
- Add their existing skills.
- Receive suitable career recommendations.
- Select a career path.
- Identify the gap between their current skills and the skills required for the selected career.
- Receive a personalized learning roadmap.
- Track their progress.

The system will include a machine learning component for career recommendation.

The system will also include a skill gap analysis component that compares the student's skills with the skills required for a selected career.

The project focuses on providing a simple and structured solution for student career exploration and skill development.

## 1.4 References

The following documents and resources are referenced:

1. Software Engineering Mini Project Guidelines.
2. Project Problem Statement #22: AI-Powered Upskilling Recommendation and Automation System for Students.
3. Publicly available datasets used for the machine learning component.
4. Standard Software Requirements Specification practices.

# 2. Overall Description

## 2.1 Product Perspective

The system will be developed as a web-based application.

The application will consist of the following main components:

- Frontend user interface.
- Backend application.
- Database.
- Machine learning model.
- Skill gap analysis module.
- Learning roadmap module.

The overall system flow is:

Student
   |
   v
User Interface
   |
   v
Student Profile and Skills
   |
   +------------------------+
   |                        |
   v                        v
Career Recommendation    Database
   |
   v
Recommended Careers
   |
   v
Student Selects Career
   |
   v
Skill Gap Analysis
   |
   v
Missing Skills
   |
   v
Learning Roadmap
   |
   v
Progress Tracking

## 2.2 Product Functions

The system will provide the following functions:

1. User registration and login.
2. Student profile management.
3. Skill management.
4. Career recommendation using a machine learning model.
5. Career path selection.
6. Skill gap analysis.
7. Learning roadmap generation.
8. Progress tracking.

## 2.3 User Classes and Characteristics

### Student

Students are the primary users of the system.

Students can:

- Register and log in.
- Manage their profile.
- Add and manage skills.
- Receive career recommendations.
- Select a career path.
- View skill gaps.
- View a learning roadmap.
- Track their learning progress.

## 2.4 Operating Environment

The system will operate in the following environment:

- **Client:** Modern web browser.
- **Operating Systems:** Windows, Linux, or macOS.
- **Frontend:** Web-based user interface.
- **Backend:** Server-side application.
- **Database:** Database for storing application data.
- **Machine Learning:** Python-based machine learning libraries may be used.

The final technologies will be selected during the implementation phase.

## 2.5 Design and Implementation Constraints

The following constraints apply:

- The project must be completed within the allocated academic timeline.
- The system must be feasible for a student development team.
- Publicly available datasets may be used for the machine learning component.
- The system should use freely available development tools and libraries.
- The system should have a modular design.
- Each major functionality should be independently testable.

## 2.6 Assumptions and Dependencies

The following assumptions are made:

- Students will provide accurate information about their skills.
- A suitable dataset will be available for career recommendation.
- Information about career paths and required skills will be available.
- Students will access the system through a supported web browser.
- The machine learning model will be trained using available data before deployment.

# 3. External Interface Requirements

## 3.1 User Interface

The system will provide a web-based user interface.

The main user interfaces will include:

- Registration page.
- Login page.
- Student dashboard.
- Profile page.
- Skill management page.
- Career recommendation page.
- Skill gap analysis page.
- Learning roadmap page.
- Progress tracking page.

The interface should be simple and easy to understand.

## 3.2 Software Interfaces

The system will interact with:

- A database for storing user and application data.
- A machine learning component for career prediction.
- Backend APIs for communication between the frontend and backend.

## 3.3 Communication Interfaces

The frontend and backend will communicate using web-based APIs.

Communication will use HTTP or HTTPS.

Data exchanged between components will use JSON format where applicable.

# 4. System Features and Functional Requirements

## 4.1 User Registration and Authentication

The system shall allow students to create an account and access the application using valid credentials.

### Functional Requirements

- **FR-01:** The system shall allow a new student to register.
- **FR-02:** The system shall validate registration information.
- **FR-03:** The system shall allow registered students to log in.
- **FR-04:** The system shall reject invalid login credentials.
- **FR-05:** The system shall allow authenticated students to log out.

## 4.2 Student Profile Management

The system shall allow students to create and manage their profile information.

Profile information may include educational information and career interests.

### Functional Requirements

- **FR-06:** The system shall allow students to view their profile.
- **FR-07:** The system shall allow students to update their profile information.
- **FR-08:** The system shall allow students to add educational information.
- **FR-09:** The system shall allow students to specify their career interests.

## 4.3 Skill Management

The system shall allow students to manage their existing skills.

### Functional Requirements

- **FR-10:** The system shall allow students to add skills.
- **FR-11:** The system shall allow students to remove skills.
- **FR-12:** The system shall store the skills associated with each student.
- **FR-13:** The system shall display the student's current skills.

## 4.4 Career Recommendation

The system shall provide suitable career recommendations based on the student's skills.

A machine learning model will analyze the available student skill information and generate career recommendations.

### Functional Requirements

- **FR-14:** The system shall accept student skill information as input.
- **FR-15:** The system shall process the student's skills using the career recommendation component.
- **FR-16:** The system shall provide one or more career recommendations.
- **FR-17:** The system shall display the recommended career paths.
- **FR-18:** The system shall allow the student to select a career path.

## 4.5 Skill Gap Analysis

The system shall identify the skills that a student needs to develop for a selected career.

The system will compare the student's existing skills with the skills required for the selected career.

### Functional Requirements

- **FR-19:** The system shall retrieve the required skills for a selected career.
- **FR-20:** The system shall retrieve the student's existing skills.
- **FR-21:** The system shall compare the student's skills with the required skills.
- **FR-22:** The system shall identify missing skills.
- **FR-23:** The system shall display the identified skill gaps.
- **FR-24:** The system shall display the student's skill match percentage.

## 4.6 Learning Roadmap Generation

The system shall generate a learning roadmap based on the skills missing from the student's profile.

The roadmap will provide a structured sequence of skills that the student should learn.

### Functional Requirements

- **FR-25:** The system shall generate a learning roadmap based on identified skill gaps.
- **FR-26:** The system shall include missing skills in the roadmap.
- **FR-27:** The system shall organize skills in a logical learning sequence.
- **FR-28:** The system shall display the learning roadmap to the student.

## 4.7 Progress Tracking

The system shall allow students to track their progress while completing the learning roadmap.

### Functional Requirements

- **FR-29:** The system shall allow students to mark roadmap items as completed.
- **FR-30:** The system shall store the student's progress.
- **FR-31:** The system shall display completed and incomplete roadmap items.
- **FR-32:** The system shall calculate the student's overall progress.
- **FR-33:** The system shall display progress information on the student dashboard.

# 5. Non-Functional Requirements

## 5.1 Performance Requirements

- **NFR-01:** The system should respond to normal user requests within an acceptable time.
- **NFR-02:** The system should retrieve and display student information efficiently.
- **NFR-03:** Career recommendations should be generated within a reasonable time.

## 5.2 Security Requirements

- **NFR-04:** The system shall require authentication to access protected user information.
- **NFR-05:** A student shall only be able to access their own information.
- **NFR-06:** User credentials shall be handled securely.
- **NFR-07:** The system shall validate user input.

## 5.3 Usability Requirements

- **NFR-08:** The system shall provide a simple and understandable user interface.
- **NFR-09:** The system shall provide feedback for user actions.
- **NFR-10:** The system shall provide meaningful error messages.
- **NFR-11:** The system should be usable on modern desktop and mobile browsers.

## 5.4 Reliability Requirements

- **NFR-12:** The system shall maintain consistency of stored data.
- **NFR-13:** The system should handle invalid input without crashing.
- **NFR-14:** The system should handle common errors gracefully.

## 5.5 Maintainability Requirements

- **NFR-15:** The system shall follow a modular design.
- **NFR-16:** The code shall be organized to allow future modifications.
- **NFR-17:** The system shall maintain appropriate project documentation.

# 6. Business Rules

The following business rules apply:

- **BR-01:** A student must register before accessing protected system features.
- **BR-02:** A student must log in before viewing or modifying their profile.
- **BR-03:** A student can only modify their own information.
- **BR-04:** Career recommendations shall be generated based on the student's available skill information.
- **BR-05:** Skill gap analysis shall compare the student's skills with the required skills of a selected career.
- **BR-06:** A learning roadmap shall be generated based on the identified skill gaps.
- **BR-07:** Only the corresponding student can update their learning progress.

# 7. Data Requirements

The system will manage the following data:

- Student account information.
- Student profile information.
- Student skills.
- Career paths.
- Skills required for career paths.
- Career recommendation data.
- Learning roadmaps.
- Student progress.

Publicly available datasets may be used to train and evaluate the career recommendation model.

# Appendix A: Glossary

| Term | Definition |
|---|---|
| AI | Artificial Intelligence |
| ML | Machine Learning |
| API | Application Programming Interface |
| SRS | Software Requirements Specification |
| Skill Gap | The difference between a student's existing skills and the skills required for a career |
| Career Path | A professional field or direction that requires a specific set of skills |
| Learning Roadmap | A structured sequence of skills that a student should learn |
| Career Recommendation | A suggestion of suitable career paths based on a student's skills |

# Appendix B: Requirement Traceability Matrix

| Requirement ID | Requirement | Module |
|---|---|---|
| FR-01 to FR-05 | User Registration and Authentication | User Management |
| FR-06 to FR-09 | Student Profile Management | Profile Management |
| FR-10 to FR-13 | Skill Management | Skill Management |
| FR-14 to FR-18 | Career Recommendation | ML Recommendation Module |
| FR-19 to FR-24 | Skill Gap Analysis | Skill Analysis Module |
| FR-25 to FR-28 | Learning Roadmap Generation | Roadmap Module |
| FR-29 to FR-33 | Progress Tracking | Progress Management |