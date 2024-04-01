// import 'package:flutter/material.dart';

// class WelcomeScreen extends StatefulWidget {
//   @override
//   _WelcomeScreenState createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   late PageController _pageController;
//   int _currentPageIndex = 0;

//   final List<Widget> _pages = [
//     _buildWelcomePage("Talk about App",
//         "LexiChat is a secure messaging app that offers end-to-end encryption and local AI processing for enhanced privacy."),
//     _buildWelcomePage("Talk about local AI and privacy",
//         "With LexiChat, your messages are processed locally on your device using AI, ensuring that your data never leaves your device and remains private."),
//     _buildWelcomePage("What you waiting for, sign up",
//         "Sign up now and experience the future of secure and private messaging with LexiChat."),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _currentPageIndex);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage("assets/images/bg-welcome-signup.jpg"),
//               fit: BoxFit.cover,
//               colorFilter: ColorFilter.mode(
//                 Colors.grey.withOpacity(0.23),
//                 BlendMode.srcATop,
//               ),
//             ),
//           ),
//           child: Center(
//             child: SizedBox(
//               width: 360,
//               height: 450,
//               child: Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.5),
//                       spreadRadius: 5,
//                       blurRadius: 7,
//                       offset: Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(
//                       child: PageView.builder(
//                         controller: _pageController,
//                         itemCount: _pages.length,
//                         itemBuilder: (context, index) {
//                           return _buildPage(index);
//                         },
//                         onPageChanged: (index) {
//                           setState(() {
//                             _currentPageIndex = index;
//                           });
//                         },
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(
//                         _pages.length,
//                         (index) => Container(
//                           width: 10,
//                           height: 10,
//                           margin: EdgeInsets.symmetric(horizontal: 4),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: _currentPageIndex == index
//                                 ? Colors.blue
//                                 : Colors.grey,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPage(int index) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           _pages[index].title,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: 20),
//         Expanded(
//           child: Text(
//             _pages[index].content,
//             style: TextStyle(
//               fontSize: 16,
//             ),
//           ),
//         ),
//         if (index == _pages.length - 1) ...[
//           SizedBox(height: 40),
//           Center(
//             child: ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/signup');
//               },
//               style: ElevatedButton.styleFrom(
//                 minimumSize: Size(200, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//               ),
//               child: Text(
//                 "Sign Up",
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   static Widget _buildWelcomePage(String title, String content) {
//     return Container(
//       child: Column(
//         children: [
//           Text(title),
//           Text(content),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class WelcomePageContent {
  final String title;
  final String content;

  WelcomePageContent(this.title, this.content);
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  final List<WelcomePageContent> _pages = [
    WelcomePageContent("Communicate with Ease and Confidence",
        "Impress everyone with tailered responses with rich vocabulary using AI assistance"),
    WelcomePageContent("Run AI locally and preserve your privacy.",
        "All data transfered is end-to-end encrypted."),
    WelcomePageContent("What you waiting for, sign up!",
        "Sign up now and experience the future of secure and private AI messaging with LexiChat."),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bg-welcome-signup.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.23),
                BlendMode.srcATop,
              ),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 360,
              height: 450,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return _buildPage(index);
                        },
                        onPageChanged: (index) {
                          setState(() {
                            _currentPageIndex = index;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          width: 10,
                          height: 10,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPageIndex == index
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _pages[index].title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Text(
          _pages[index].content,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        if (index == _pages.length - 1) ...[
          SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                "Sign Up",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
