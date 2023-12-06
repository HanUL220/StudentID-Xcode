import SwiftUI
import CoreImage.CIFilterBuiltins

struct StudentID: Identifiable {
    let id = UUID()
    let name: String
    let studentID: String
    let department: String
    let barcodeImage: Image
    let qrCodeImage: Image

    init(name: String, studentID: String, department: String) {
        self.name = name
        self.studentID = studentID
        self.department = department
        self.barcodeImage = Self.generateBarcode(from: studentID)
        self.qrCodeImage = Self.generateQRCode(from: studentID)
    }

    static func generateBarcode(from string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                return Image(uiImage: uiImage)
            }
        }
        return Image(systemName: "xmark.circle")
    }

    static func generateQRCode(from string: String) -> Image {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                let uiImage = UIImage(cgImage: cgImage)
                return Image(uiImage: uiImage)
            }
        }
        return Image(systemName: "xmark.circle")
    }
}

struct CardView: View {
    let studentID: StudentID

    var body: some View {
        ZStack {
            Color.white
            VStack {
                Text("학생증")
                    .font(.system(size: 30))
                    .padding(20)

                studentID.barcodeImage
                    .resizable()
                    .frame(width: 350, height: 100)

                Text("이름 : \(studentID.name)\t\t 학번 : \(studentID.studentID)")
                    .font(.system(size: 20))
                Text("전공 : \(studentID.department)")
                    .font(.system(size: 20))
                    .padding()

                studentID.qrCodeImage
                    .resizable()
                    .frame(width: 90, height: 90)
            }
        }
        .cornerRadius(10)
        .frame(width: 300, height: 590)
        .shadow(radius: 5)
        .position(x: UIScreen.main.bounds.width / 2 - 20, y: UIScreen.main.bounds.height / 2 - 125)

    }
}

struct ContentView: View {
    @State private var name = ""
    @State private var studentID = ""
    @State private var department = ""
    @State private var myPasses: [StudentID] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        TabView {
            // 학생증 추가 탭
            NavigationView {
                VStack {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 80))
                        .padding()
                        .padding()
                        .imageScale(.large)
                        .foregroundStyle(.tint)

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
                        .onChange(of: studentID) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            studentID = String(filtered.prefix(9))
                        }

                    Text("전공 :")
                        .font(.system(size: 25))
                    TextField("Enter your department", text: $department)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        if let existingStudentID = myPasses.first {
                            showingAlert = true
                            alertMessage = "이미 있는 학생증을 삭제하세요."
                        } else if name.isEmpty || studentID.isEmpty || department.isEmpty {
                            showingAlert = true
                            alertMessage = "모든 필드를 채워주세요."
                        } else {
                            let newStudentID = StudentID(name: name, studentID: studentID, department: department)
                            myPasses.append(newStudentID)
                            name = ""
                            studentID = ""
                            department = ""
                        }
                    }) {
                        Text("나의 학생증 만들기")
                            .padding()
                            .padding()
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
                    }
                }
                .padding()
                .navigationTitle("학생증 만들기")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
