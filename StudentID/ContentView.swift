import SwiftUI
import CoreImage.CIFilterBuiltins

// 학생증 모델
struct StudentID: Identifiable {
    let id = UUID()
    let name: String
    let studentID: String
    let department: String
    let barcodeImage: Image
    let qrCodeImage: Image
    var profileImage: Image? // 프로필 이미지 추가

    // 초기화 메서드
    init(name: String, studentID: String, department: String, profileImage: UIImage?) {
        self.name = name
        self.studentID = studentID
        self.department = department
        self.barcodeImage = Self.generateBarcode(from: studentID)
        self.qrCodeImage = Self.generateQRCode(from: studentID)
        if let profileImage = profileImage {
            self.profileImage = Image(uiImage: profileImage)
        }
    }

    // 바코드 이미지 생성
    static func generateBarcode(from string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                return Image(uiImage: uiImage)
            }
        }
        return Image(systemName: "xmark.circle")
    }

    // QR 코드 이미지 생성
    static func generateQRCode(from string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")

        if let qrCodeImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledCIImage = qrCodeImage.transformed(by: transform)
            if let qrCodeCGImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) {
                let uiImage = UIImage(cgImage: qrCodeCGImage)
                return Image(uiImage: uiImage)
            }
        }

        return Image(systemName: "xmark.circle")
    }
}

// 학생증 카드 뷰
struct CardView: View {
    let studentID: StudentID

    var body: some View {
        ZStack {
            Color.white
            VStack {
                Text("학생증")
                    .font(.system(size: 30))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 35)

                studentID.barcodeImage
                    .resizable()
                    .frame(width: 350, height: 120)

                Text("이름 : \(studentID.name)\t\t 학번 : \(studentID.studentID)")
                    .font(.system(size: 20))
                Text("전공 : \(studentID.department)")
                    .font(.system(size: 20))
                    .padding()

                studentID.qrCodeImage
                    .resizable()
                    .frame(width: 120, height: 120)
            }
            if let profileImage = studentID.profileImage {
                profileImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
//                    .clipShape(Circle())
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .offset(x: 115, y: -190) // 오른쪽 상단으로 이동
            }
        }
        .cornerRadius(10)
        .frame(width: 350, height: 500)
        .shadow(radius: 5)
    }
}

// 이미지 피커
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        // 이미지 선택 후 처리
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = cropImageToSquare(image: uiImage)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }

        // 이미지를 1:1 비율로 크롭
        func cropImageToSquare(image: UIImage) -> UIImage {
            let cgImage = image.cgImage!
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let shorterSide = min(imageSize.width, imageSize.height)
            let size = CGSize(width: shorterSide, height: shorterSide)

            let x = (imageSize.width - shorterSide) / 2
            let y = (imageSize.height - shorterSide) / 2
            let cropRect = CGRect(x: x, y: y, width: size.width, height: size.height)

            if let croppedCGImage = cgImage.cropping(to: cropRect) {
                return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
            }

            return image
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

// 메인 화면
struct ContentView: View {
    @State private var name = ""
    @State private var studentID = ""
    @State private var department = ""
    @State private var myPasses: [StudentID] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        TabView {
            // 학생증 추가 탭
            NavigationView {
                VStack {
                    HStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 170, height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding()
                        } else {
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 80))
                                .padding()
                                .imageScale(.large)
                                .foregroundStyle(.tint)
                                .padding()
                        }

                        Button(action: {
                            isImagePickerPresented.toggle()
                        }) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 35))
                                .padding()
                        }
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(isPresented: $isImagePickerPresented, selectedImage: $selectedImage)
                        }
                    }

                    Text("성함 :")
                        .font(.system(size: 25))
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Text("학번 :")
                        .font(.system(size: 25))
                    TextField("Enter your student ID", text: $studentID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding()
                        .onChange(of: studentID) { _ in
                            let filtered = studentID.filter {
                                "0123456789".contains($0)
                            }
                            studentID = String(filtered.prefix(9))
                        }

                    Text("전공 :")
                        .font(.system(size: 25))
                    TextField("Enter your department", text: $department)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        if myPasses.first != nil {
                            showingAlert = true
                            alertMessage = "이미 있는 학생증을 삭제하세요."
                        } else if name.isEmpty || studentID.isEmpty || department.isEmpty {
                            showingAlert = true
                            alertMessage = "모든 필드를 채워주세요."
                        } else {
                            let newStudentID = StudentID(name: name, studentID: studentID, department: department, profileImage: selectedImage)
                            myPasses.append(newStudentID)
                            name = ""
                            studentID = ""
                            department = ""
                            selectedImage = nil
                            
                            //showingAlert = true
                            //alertMessage = "현재 학생증을 Apple Wallet에 추가는 추후 업데이트 예정 입니다.\n학생증 이미지를 캡쳐하여 사용해보세요."
                        }
                    }) {
                        Text("나의 학생증 만들기")
                            .padding()
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
                    }
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("학생증 만들기")
                            .font(.largeTitle)
                            .padding(.top, 50)
                    }
                }
            }
            .tabItem {
                Label("학생증 추가", systemImage: "plus")
            }

            // 나의 학생증 탭
            NavigationView {
                List {
                    ForEach(myPasses) { studentID in
                        CardView(studentID: studentID)
                    }
                    .onDelete(perform: deleteStudentID)
                    
                    if !myPasses.isEmpty {
                        // Apple Wallet 추가 버튼 (기능 제공 안 함)
                        Button(action: {
                            showingAlert = true
                            alertMessage = "현재 학생증을 Apple Wallet에 추가는 추후 업데이트 예정 입니다.\n학생증 이미지를 캡쳐하여 사용해보세요."
                        }) {
                            HStack {
                                Image(systemName: "wallet.pass")
                                    .foregroundColor(.blue)
                                Text("Apple Wallet에 추가")
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                }
                .listStyle(PlainListStyle())
                .navigationTitle("나의 학생증")
            }
            .tabItem {
                Label("나의 학생증", systemImage: "person")
            }

            // 설정 탭
            NavigationView {
                Text("설정")
                    .navigationBarTitle("설정")
            }
            .tabItem {
                Label("설정", systemImage: "gear")
            }
        }
    }

    func deleteStudentID(at offsets: IndexSet) {
        myPasses.remove(atOffsets: offsets)
    }
}

// 미리보기
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
