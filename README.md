# UnluckyDraw - iOS App Setup Guide

## 🛠️ Xcode에서 추가 설정 필요

### 1. Info.plist 권한 추가
Xcode에서 다음 권한들을 Info.plist에 추가해주세요:

```xml
<key>NSCameraUsageDescription</key>
<string>UnluckyDraw needs camera access to take photos and detect faces for the drawing game.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>UnluckyDraw may access your photo library to select images for face detection.</string>
```

또는 Xcode Target Settings에서:
- **Camera Usage Description**: "UnluckyDraw needs camera access to take photos and detect faces for the drawing game."
- **Photo Library Usage Description**: "UnluckyDraw may access your photo library to select images for face detection."

### 2. 필요한 Frameworks 확인
다음 프레임워크들이 자동으로 링크되어 있는지 확인:
- ✅ SwiftUI (기본 포함)
- ✅ Vision (iOS 기본 프레임워크)
- ✅ AVFoundation (카메라용)
- ✅ UIKit (이미지 처리용)

### 3. 최소 iOS 버전
현재 iOS 18.5로 설정되어 있습니다. Vision Framework를 위해 iOS 13.0 이상이면 충분합니다.

## 📱 앱 기능 요약

### ✨ 구현된 기능들:
1. **홈 화면**: 모드 선택 (Photo/Number/Name Draw)
2. **Photo Draw 모드** (완전 구현):
   - 📸 카메라로 사진 촬영
   - 🤖 AI 얼굴 인식 (Vision Framework)
   - 🎰 룰렛 애니메이션 (얼굴 순환)
   - 🎯 당첨자 결과 화면
   - 🎊 축하 애니메이션 & 햅틱 피드백

3. **UI/UX 디자인**:
   - Apple HIG 준수
   - 직관적인 네비게이션
   - 부드러운 애니메이션
   - 접근성 고려

### 🎮 앱 플로우:
```
홈화면 → Photo Draw 선택
    ↓
사용법 안내
    ↓
카메라 촬영
    ↓
얼굴 인식 & 확인
    ↓
룰렛 애니메이션
    ↓
당첨자 발표
    ↓
다시 하기 or 종료
```

## 🎨 디자인 시스템

### 색상 팔레트:
- **Primary Red**: 메인 브랜드 컬러
- **Primary Orange**: 보조 컬러
- **Highlight Yellow**: 룰렛 하이라이트
- **Winner Green**: 당첨자 표시
- **Dark Gray**: 텍스트
- **Light Gray**: 배경

### 컴포넌트:
- **카드 스타일**: 둥근 모서리 + 그림자
- **버튼 스타일**: 색상별 템플릿
- **애니메이션**: Spring, Ease-out 활용

## 🔧 기술 구조 (MVC)

### Models:
- `DrawMode.swift`: 게임 모드 열거형
- `DetectedFace.swift`: 얼굴 데이터 모델

### Views:
- `HomeView.swift`: 메인 홈 화면
- `PhotoDrawView.swift`: 사진 뽑기 컨테이너
- `FaceDetectionView.swift`: 얼굴 인식 결과
- `RouletteView.swift`: 룰렛 애니메이션
- `ResultView.swift`: 결과 발표

### Controllers:
- `FaceDetectionController.swift`: Vision Framework 관리
- `RouletteController.swift`: 룰렛 로직 & 애니메이션

### Utils:
- `CameraManager.swift`: 카메라 권한 & 촬영
- `Extensions.swift`: 유틸리티 & 스타일링

## 🚀 빌드 & 실행

### 필수 요구사항:
- Xcode 15.0+
- iOS 13.0+ 기기 (얼굴 인식용)
- 카메라가 있는 실제 디바이스 (시뮬레이터 제한)

### 빌드 단계:
1. Xcode에서 프로젝트 열기
2. Info.plist에 카메라 권한 추가
3. 실제 디바이스 연결
4. Build & Run (⌘+R)

## 🎯 향후 개발 계획

### Phase 2 - 추가 모드:
- **Number Draw**: 숫자 범위 설정 뽑기
- **Name Draw**: 이름 목록 입력 뽑기

### Phase 3 - 고급 기능:
- 🎵 사운드 이펙트
- 📊 통계 기능 (누가 가장 많이 당첨됐는지)
- 🎨 테마 변경
- 📤 결과 공유 기능

### Phase 4 - 소셜 기능:
- 👥 그룹 만들기
- 🏆 리더보드
- 📱 멀티플레이어

## 🐛 알려진 제한사항

1. **카메라 필수**: 시뮬레이터에서 완전 테스트 불가
2. **얼굴 인식 정확도**: 조명, 각도에 영향받음
3. **성능**: 고해상도 이미지에서 처리 시간 증가 가능

## 📝 App Store 출시 준비

### 체크리스트:
- [ ] 앱 아이콘 디자인
- [ ] 스크린샷 준비 (6.7", 6.5", 5.5" 필수)
- [ ] 앱 설명 작성 (한국어/영어)
- [ ] 개인정보 처리방침 작성
- [ ] 베타 테스트 (TestFlight)
- [ ] App Store Review Guidelines 준수 확인

### 권장 카테고리:
- **Entertainment** 또는 **Games**
- 연령 등급: 4+ (모든 연령 사용 가능)

## 💡 마케팅 아이디어

### 앱 스토어 키워드:
- "party game", "group activity", "face detection"
- "decision maker", "random picker", "fun app"

### 타겟 사용자:
- 🎉 파티/모임 주최자
- 👥 친구/가족 그룹
- 🎯 결정장애 해결사
- 🎮 캐주얼 게임 사용자

---

**🎯 이제 Xcode에서 빌드해서 실제 디바이스에서 테스트해보세요!**

카메라 권한과 얼굴 인식이 제대로 작동하는지 확인하고, 개선할 부분이 있으면 알려주세요.
