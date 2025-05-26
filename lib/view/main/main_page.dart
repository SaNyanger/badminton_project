import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badminton_project/view/auth/auth_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/user.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BaddyUser currentUser = Get.find();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentUser.name}님 안녕하세요!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            currentUser.groupId.isEmpty
                ? const Text(
                  "소속 그룹 없음",
                  style: TextStyle(color: Colors.white70),
                )
                : FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .doc(currentUser.groupId)
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        "소속 불러오는 중...",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
                      return const Text(
                        "소속 정보 없음",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      );
                    }

                    final data = snapshot.data!.data();
                    if (data == null) {
                      return const Text(
                        "소속 정보 없음",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      );
                    }
                    final groupData = data as Map<String, dynamic>;
                    return Text(
                      '소속: ${groupData['name'] ?? '소속 정보 없음'}',
                      style: const TextStyle(fontSize: 17, color: Colors.white70),
                    );
                  },
                ),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              currentUser.groupId.isEmpty
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection('baddyusers')
                      .where('groupId', isEqualTo: currentUser.groupId)
                      .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!.docs;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['name'] ?? '알 수 없음', style: TextStyle(fontSize: 20,),),
                  //subtitle: Text(user['email']),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text('${user['name']}의 전적'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("승률: ${user['winRate'] ?? '정보 없음'}"),
                                const SizedBox(height: 8),
                                ...(user['recentMatches'] as List<dynamic>? ??
                                        [])
                                    .map((match) => Text(match))
                                    .toList(),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('닫기'),
                              ),
                            ],
                          ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed, // <-- 아이콘 색 고정
        selectedLabelStyle: TextStyle(color: Colors.white),
        unselectedLabelStyle: TextStyle(color: Colors.white54),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈',),
          BottomNavigationBarItem(icon: Icon(Icons.sports), label: '경기기록'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: '로그아웃'),
        ],
          onTap: (index) {
            switch (index) {
              case 0:
                Get.offAll(() => MainPage());
                break;
              case 1:
                //Get.to(() => RecordPage()); ⭐ 기안님 추가
                break;
              case 2:
                //Get.to(() => MapPage()); ⭐기안님 추가
                break;
              case 3:
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text("로그아웃", style: TextStyle(color: Colors.black),),
                    content: const Text("로그아웃 하시겠습니까?", style: TextStyle(color: Colors.black),),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("아니오", style: TextStyle(color: Colors.black),),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          try {
                            await GoogleSignIn().signOut(); // 구글 로그아웃 병행했다면
                          } catch (_) {}

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear(); // 저장된 로그인 정보 제거

                          Get.offAll(() => const AuthPage());
                        },
                        child: const Text("예", style: TextStyle(color: Colors.black),),
                      ),
                    ],
                  ),
                );
                break;
            }
          }
      ),
    );
  }
}
