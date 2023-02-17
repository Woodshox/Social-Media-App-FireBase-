//
//  LoginView.swift
//  SocialMedia
//
//  Created by Aleksandr Pavlov on 10.02.23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

//Building Login Page UI

struct LoginView: View {
    //MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    // MARK: View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    //MARK: User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Lets Sign You in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome Back\nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12) {
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 25)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button("Reset Password?", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.black)
                    .hAlign(.trailing)
                
                Button(action: loginUser) {
                    //MARK: Login Button
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top, 10)
            }
            
            //MARK: Register Button
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                
                
                Button("Register now") {
                    // При нажатии на клавишу мы переключаем значение @State парамерта на противоположенный,
                    //в нашем случае это  true
                    createAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
                
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        // MARK: Register View VIA Sheets
        
        .fullScreenCover(isPresented: $createAccount) {
            //теперь когда переключатель переключен в другое положение мы вызываем метод .fullScreen  который
            // переводит нас на любой нужный нам экран но только при условии что наш переключатель теперь
            // находится в положении true
            RegisterView()
        }
        // MARK: Displaying alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func loginUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                //Mark: With the help of swift Concurrency Auth can be with Single Line
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
            }catch{
                debugPrint(error)
                await setError(error)
            }
        }
    }
    
    //Mark: If User is Found then Fetching User Data From Firestore
    func fetchUser()async throws {
        guard let userID = Auth.auth().currentUser?.uid else{return}
        let user = try await Firestore.firestore().collection("User").document(userID).getDocument(as: User.self)
        //MARK: UI Updating must be run on main Thread
        await MainActor.run(body: {
            // Setting userDefauls data and Changing Apps Auth Status
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
            
        })
    }
    
    func resetPassword() {
        Task {
            do {
                //Mark: With the help of swift Concurrency Auth can be with Single Line
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            }catch{
                await setError(error)
            }
        }
    }
    
    
    // MARK: Dsaplying Errors VIA Alert
    func setError(_ error: Error)async {
        //Mark: UI MUST be Updated on Mail Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

// MARK: Register View
struct RegisterView: View {
    //MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    //MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var alreadyHaveAccount: Bool = false
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    //MaRK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Lets Register \nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Hello user, have a wonderful jorney")
                .font(.title3)
                .hAlign(.leading)
            
            //MARK: For smaller Size Optimization
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                HelperView()
            }
            
            
            //MARK: Register Button
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.gray)
                
                Button("Login Now") {
                    
                    /*есть два способа вернуть назад наш прежний View, мы можем либо
                     отменить тот что мы только что  меняли, а можем создать новый Тоггл и
                     переключать его чтобы вызвать первое  View. Какой из способов правильный
                     и какой ест меньше памяти я сказать не могу*/
                    
                    
                    //alreadyHaveAccount.toggle()
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
                
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        /* Функция .onChange вызывается с аргументом of: photoItem, который указывает, что обработчик событий прослушивает изменения в объекте photoItem. Аргумент newValue - это новое значение объекта photoItem после изменения.
         */
        .onChange(of: photoItem) { newValue in
            // MARK: Extracting UIImage From PhotoItem
            if let newValue {
                Task {
                    /* Код внутри обработчика события используется для извлечения UIImage из объекта photoItem. Для этого используется метод loadTransferable объекта photoItem, который должен вернуть данные типа Data. Затем данные приводятся к UIImage и сохраняются в переменной userProfilePicData.
                     */
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        //MARK: UI Must Be Update on Main Thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                        
                    }catch{}
                }
            }
        }
        
        //        .fullScreenCover(isPresented: $alreadyHaveAccount) {
        //            LoginView()
        //        }
        
        // Mark: Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    
    
    @ViewBuilder
    //Узнать что это такое View Builder
    func HelperView()->some View {
        VStack(spacing: 12) {
            
            ZStack {
                if let userProfilePicData, let image = UIImage(data: userProfilePicData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image("image")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top, 25)
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("About You", text: $userBio, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            Button(action: registerUser) {
                //MARK: Login Button
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top, 10)
        }
    }
    
    func registerUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                // Step 1 Creating Firebase Account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                // Step 2 Uploading Profile Photo Into Firebase Storage
                guard let userID = Auth.auth().currentUser?.uid else{return}
                guard let imageData = userProfilePicData else{return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userID)
                let _ = try await storageRef.putDataAsync(imageData)
                //Step 3 Downloading Photo URL
                let downloadURL = try await storageRef.downloadURL()
                // Step 4 Creating a User Firestore Object
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userID, userEmail: emailID, userProfileURL: downloadURL)
                // Step 5 Saving User Doc into Firestore Database
                let _ = try Firestore.firestore().collection("Users").document(userID).setData(from: user, completion: {
                    error in
                    if error == nil {
                        // MARK : Print Saved Succesfully
                        print("Saved Succesfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
            }catch{
                // MARK Deleting Created Account In Case of Failure
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    func setError(_ error: Error)async {
        //Mark: UI MUST be Updated on Mail Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
//MARK: View Extensions for UI Building
extension View {
    //Close All Active Keyboards
    func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    // MARK: Disableing with Opacity
    func disableWithOpacity(_ condition: Bool)-> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.6 :1)
    }
    
    func hAlign(_ alignment: Alignment)->some View {
        self
            .frame(maxWidth: .infinity,alignment: alignment)
    }
    
    func vAlign(_ alignment: Alignment)-> some View {
        self
            .frame(maxHeight: .infinity,alignment: alignment)
    }
    
    //MARK: Custom Border View WithPaddng
    func border(_ width: CGFloat,_ color: Color)->some View {
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(color, lineWidth: width)
            }
    }
    
    //MARK: Custom Fill View WithPaddng
    func fillView(_ color: Color)->some View {
        self
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color)
            }
    }
    
}
