# 📊 Module 2 Progress Tracker (`saving_discipline_and_momo`)
**Project:** Travel Buddy (PTUDDD - Group 08 - 65KTPM)  
**Lead Engineer:** Nguyen Xuan Binh (Member #2 - 64KTPM5)  
**Branch:** `feat/saving-models-calculator`  

---

## 🟢 Phase 1: Data Foundations & Saving Plan Generator

| Task | Description | Status | Verification / Artifacts |
| :--- | :--- | :---: | :--- |
| **Task 1.1** | Define Data Models & Entities (`MoMoFundConfig`, `SavingPlan`, `DepositRecord`, `MemberStreak`) | **COMPLETED** | Models created with Firestore serialization, deserialization, and null safety: <br>- `models/momo_fund_config.dart`<br>- `models/saving_plan.dart`<br>- `models/deposit_record.dart`<br>- `models/member_streak.dart` |
| **Task 1.2** | Implement Saving Plan Calculator (`SavingCalculator`) | **COMPLETED** | Domain calculation logic implemented in `utils/saving_calculator.dart` with 100% boundary test coverage. All 6 unit tests passed in `test/features/saving_discipline_and_momo/saving_calculator_test.dart`. |
| **Task 1.3** | Build Saving Repository Layer (`SavingRepository` & `SavingRepositoryImpl`) | **COMPLETED** | Abstract contract & Firestore + Firebase Storage implementation created with atomic transactions: <br>- `repository/saving_repository.dart`<br>- `repository/saving_repository_impl.dart` |
| **Task 1.4 (Phase 1 Vertical Slice Completion)** | Riverpod Saving Plan State Management & UI Screen | **COMPLETED** | End-to-end slice connecting Models + Calculator + Repository to UI: <br>- `providers/saving_plan_provider.dart` (`AsyncNotifierProvider`)<br>- `presentation/screens/saving_plan_screen.dart` (Live breakdown, installment schedule preview, form validation & progress tracking) |

### 🎯 Checkpoint 1 Status: Passed ✅
- [x] Data models compile with null safety.
- [x] Unit tests for `SavingCalculator` pass with 100% boundary coverage (6/6 tests passing).
- [x] Repository layer implemented with atomic Firestore transaction and Riverpod provider.
- [x] Riverpod `savingPlanProvider` (`AsyncNotifierProvider.autoDispose.family`) implemented with `AsyncValue.guard()`.
- [x] `SavingPlanScreen` UI widget built for periodic saving plan generation and review.
- [x] Static analysis: `flutter analyze` reports 0 issues (0 errors, 0 warnings).

---

## 🟡 Phase 2: MoMo Group Fund & Camera QR Scanner
- [ ] Task 2.1: Host MoMo Fund Setup Screen
- [ ] Task 2.2: Live Camera QR Scanner via `mobile_scanner`
- [ ] Task 2.3: 1-Tap MoMo Deeplink & Payment View

## 🟠 Phase 3: DailyYou-Style Saving Streak Calendar
- [ ] Task 3.1: Saving Streak Calculation Logic
- [ ] Task 3.2: DailyYou Streak Calendar UI Widget
- [ ] Task 3.3: Emotion Tags & Saving Journal Dialog

## 🔵 Phase 4: Receipt Upload, Host Approval & Fund Progress
- [ ] Task 4.1: Transfer Receipt Upload to Firebase Storage
- [ ] Task 4.2: Host Receipt Review & Verification Screen
- [ ] Task 4.3: Realtime Fund Progress Bar & Leaderboard Card

## 🟣 Phase 5: Routing Integration & Quality Polish
- [ ] Task 5.1: Encapsulate Module Routing Contract
- [ ] Task 5.2: Static Analysis & Code Quality Verification
