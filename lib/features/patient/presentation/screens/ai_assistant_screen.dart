import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medilab_prokit/core/theme/colors.dart';
import 'package:medilab_prokit/main.dart';
import 'package:nb_utils/nb_utils.dart';

class MLAiAssistantScreen extends StatefulWidget {
  static String tag = '/MLAiAssistantScreen';

  const MLAiAssistantScreen({super.key});

  @override
  MLAiAssistantScreenState createState() => MLAiAssistantScreenState();
}

class MLAiMessage {
  final bool isUser;
  final String text;
  MLAiMessage({required this.isUser, required this.text});
}

class MLAiAssistantScreenState extends State<MLAiAssistantScreen> {
  TextEditingController messageController = TextEditingController();
  List<MLAiMessage> messages = [
    MLAiMessage(
      isUser: false,
      text: 'Bonjour ! Je suis votre assistant médical IA. '
            'Je peux vous aider à comprendre vos bilans, vos ordonnances ou préparer vos questions pour le médecin.',
    ),
    MLAiMessage(isUser: true, text: 'Que signifie ma glycémie à jeun ?'),
    MLAiMessage(
      isUser: false,
      text: 'Votre dernier résultat indique 0.92 g/L, ce qui se situe dans la plage normale (0.70 à 1.10 g/L). '
            'Aucune inquiétude à ce stade.',
    ),
  ];
  final List<String> suggestions = [
    'Expliquer mon bilan',
    'Mes médicaments',
    'Prendre un rendez-vous',
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = appStore.isDarkModeOn;

    return SafeArea(
      child: Scaffold(
        backgroundColor: mlPrimaryColor,
        body: Stack(
          children: [
            Positioned(
              top: 8.0,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: medicalTealDark,
                        child: Icon(Icons.auto_awesome, color: white, size: 24),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 6,
                        child: Icon(Icons.brightness_1_rounded, color: Colors.greenAccent, size: 14),
                      ),
                    ],
                  ),
                  8.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assistant IA Medilink', style: boldTextStyle(color: whiteColor, size: 18)),
                      4.height,
                      Text('En ligne', style: secondaryTextStyle(size: 16, color: white.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ).paddingAll(16.0),
            ),
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: context.width(),
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radiusOnly(topRight: 32),
                  backgroundColor: isDark ? black : white,
                ),
                child: Column(
                children: [
                  Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.0),
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final MLAiMessage message = messages[messages.length - 1 - index];
                        if (message.isUser) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: EdgeInsets.all(12.0),
                              constraints: BoxConstraints(maxWidth: context.width() * 0.75),
                              decoration: boxDecorationWithRoundedCorners(
                                backgroundColor: medicalTealPrimary,
                                borderRadius: radius(14.0),
                              ),
                              child: Text(message.text, style: primaryTextStyle(color: white, size: 14)),
                            ),
                          );
                        }
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: medicalTealDark,
                                child: Icon(Icons.auto_awesome, color: white, size: 14),
                              ),
                              8.width,
                              Container(
                                padding: EdgeInsets.all(12.0),
                                constraints: BoxConstraints(maxWidth: context.width() * 0.75),
                                decoration: boxDecorationWithRoundedCorners(
                                  backgroundColor: isDark ? scaffoldDarkColor : mlColorLightGrey100,
                                  borderRadius: radius(14.0),
                                ),
                                child: Text(
                                  message.text,
                                  style: primaryTextStyle(color: isDark ? white : blackColor, size: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).expand(),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? scaffoldDarkColor : medicalTealUltraLight,
                            borderRadius: radius(20),
                            border: Border.all(color: medicalTealPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            suggestions[index],
                            style: secondaryTextStyle(size: 13, color: medicalTealDark),
                          ),
                        ).onTap(() {
                          addMessage(suggestions[index]);
                        });
                      },
                    ),
                  ),
                  8.height,
                ],
              ),
            ).paddingTop(8.0),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: MediaQuery.of(context).viewInsets,
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: context.cardColor,
            borderRadius: radius(0.0),
            border: Border.all(color: mlColorLightGrey100),
          ),
          child: Row(
            children: [
              16.width,
              Icon(CupertinoIcons.smiley, size: 22, color: Colors.grey.shade600),
              8.width,
              Icon(Icons.mic_none, size: 22, color: Colors.grey.shade600),
              8.width,
              AppTextField(
                controller: messageController,
                textFieldType: TextFieldType.OTHER,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Posez votre question...',
                  hintStyle: secondaryTextStyle(size: 16),
                ),
              ).expand(),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: medicalTealPrimary, shape: BoxShape.circle),
                child: Icon(Icons.send_outlined, size: 20, color: white),
              ).paddingAll(4.0).onTap(
                () {
                  addMessage(messageController.text);
                  messageController.clear();
                },
              ),
              8.width,
            ],
          ),
        ),
      ),
    );
  }

  void addMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(
      () {
        messages.insert(0, MLAiMessage(isUser: true, text: text));
      },
    );
  }
}
