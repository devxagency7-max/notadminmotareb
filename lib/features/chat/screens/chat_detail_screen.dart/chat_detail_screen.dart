import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text': 'مرحباً! أنا وكيلك المعتمد. كيف يمكنني مساعدتك؟',
      'time': '10:30 ص',
    },
    {
      'isMe': true,
      'text': 'مرحباً، أرغب في الاستفسار عن الشقة في حي النخيل',
      'time': '10:32 ص',
    },
    {
      'isMe': false,
      'text': 'بالتأكيد! الشقة متاحة حالياً. هل لديك أي أسئلة محددة؟',
      'time': '10:33 ص',
    },
    {'isMe': true, 'text': 'هل الإنترنت مشمول في السعر؟', 'time': '10:35 ص'},
    {
      'isMe': false,
      'text':
          'نعم، الإنترنت عالي السرعة مشمول في السعر. كذلك الكهرباء والماء 💡',
      'time': '10:36 ص',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF008695),
                    child: Text(
                      'ع',
                      style: TextStyle(color: Colors.white),
                    ), // Placeholder initials
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الوكيل المعتمد',
                    style: GoogleFonts.cairo(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'متصل الآن',
                    style: GoogleFonts.cairo(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  bool isMe = msg['isMe'];
                  return FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Align(
                      alignment: isMe
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          // Gradient for Receiver (Agent), White for Sender (User)
                          gradient: !isMe
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF39BB5E),
                                    Color(0xFF008695),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMe ? Colors.white : null,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(!isMe ? 20 : 0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['text'],
                              style: GoogleFonts.cairo(
                                color: !isMe ? Colors.white : Colors.black87,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              msg['time'],
                              style: GoogleFonts.cairo(
                                color: !isMe ? Colors.white70 : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Security Note
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.white.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    'جميع المحادثات آمنة ومراقبة لحمايتك',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Attachment
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  // Text Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك...',
                          hintStyle: GoogleFonts.cairo(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send Button
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
