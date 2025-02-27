import 'package:donation_app_v1/const_values/feedback_page_values.dart';
import 'package:donation_app_v1/const_values/title_values.dart';
import 'package:donation_app_v1/enums/drawer_enum.dart';
import 'package:donation_app_v1/models/drawer_model.dart';
import 'package:donation_app_v1/models/profile_model.dart';
import 'package:donation_app_v1/models/settings_model.dart';
import 'package:donation_app_v1/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



final _supabaseClient = Supabase.instance.client; // Initialize Supabase Client

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  TextEditingController feedbackText=TextEditingController(text: '');
  bool isSubmitted=false;
  double rating=0.0;

  String getCurrentLanguage()  {
    // Ensure that the Hive box is open. If already open, this returns the box immediately.
    final Box<Settings> settingsBox = Hive.box<Settings>('settingsBox');

    // Retrieve stored settings or use default settings if none are stored.
    final Settings settings = settingsBox.get('userSettings', defaultValue: Settings.defaultSettings)!;

    // Return the current language as an enum.
    return  settings.language;
  }
  @override
  Widget build(BuildContext context) {
    final profileProvider=Provider.of<ProfileProvider>(context,listen: false);
    return Scaffold(
        backgroundColor: Colors.white,
        drawer: DonationAppDrawer(drawerIndex: DrawerItem.feedback.index),
        appBar: AppBar(
          backgroundColor: Colors.teal.shade200,

          centerTitle: true,
          title: Text(PageTitles.getTitle(getCurrentLanguage(), 'feedback_page_title')),
        ),
        body: ChangeNotifierProvider(create:(context) =>  FeedbackProvider(),builder: (context, child) => isSubmitted ?
        ListView(
            children:[
              Image.asset('assets/images/feedback.png'),
              Container(

                margin: EdgeInsets.only(top:1,left: 15,right: 15),
                padding: EdgeInsets.symmetric(vertical: 30,horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0,0), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      FeedbackLabels.getFeedbackLabel(getCurrentLanguage(), 'thanks_feedback'),
                      style: TextStyle(fontSize: 22.0),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 6.0),
                    Text(
                      FeedbackLabels.getFeedbackLabel(getCurrentLanguage(), 'we_consider_text'),
                      style: TextStyle(fontSize: 12.0),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.0),
                    MaterialButton(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      color: Colors.green,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context,'/donation');
                      },
                      child: Text(FeedbackLabels.getFeedbackLabel(getCurrentLanguage(), 'go_back_button'),style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                    ),

                  ],
                ),
              ),

            ]
        )
            : ListView(
            children:[
              Image.asset('assets/images/feedback.png'),

              Container(

                margin: EdgeInsets.only(top:1,left: 15,right: 15),
                padding: EdgeInsets.symmetric(vertical: 30,horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: Offset(0,0), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      FeedbackLabels.getFeedbackLabel(getCurrentLanguage(), 'send_feedback_text'),
                      style: TextStyle(fontSize: 22.0),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 26.0),
                    Center(
                      child: Container(
                        child: FiveStarRating(),
                      ),
                    ),

                    SizedBox(height: 26.0),
                    TextFormField(
                      minLines: 5,
                      maxLines: 20,
                      controller: feedbackText,
                      decoration: InputDecoration(
                        hintText: FeedbackLabels.getFeedbackLabel(getCurrentLanguage(), 'enter_feedback_hint'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20)
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0,vertical: 18),
                child: MaterialButton(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  color: Colors.teal,
                  textColor: Colors.white,
                  onPressed: () {
                    // Add your feedback submission logic here
                    if(feedbackText.text!=''){
                      final feedbackProvider=Provider.of<FeedbackProvider>(context,listen: false);

                      setState(() {

                        isSubmitted=true;
                        FeedbackModel tempFeedback=FeedbackModel(user: _supabaseClient.auth.currentUser!.userMetadata!['username'] ?? "User",email: _supabaseClient.auth.currentUser!.email ?? "user@example.com",starRate: feedbackProvider.star_rating, message: feedbackText.text,profileId: _supabaseClient.auth.currentUser!.id );
                        print(feedbackProvider.star_rating);

                        saveFeedback(tempFeedback);
                        print(feedbackProvider.star_rating);
                      });
                    }else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No Feedback Text Found!'),
                        ),
                      );
                    }
                  },
                  child: Text(FeedbackLabels.getFeedbackLabel(getCurrentLanguage(), 'submit_feedback_button'),style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                ),
              ),
            ]
        ),)
    );
  }
}

Future<void> saveFeedback(FeedbackModel feedbackModel) async {
  try {
    final response = await _supabaseClient.from('feedback').insert(feedbackModel.toMap());


    print('Weekly report saved successfully!');
  } catch (error) {
    print('Error saving weekly report: $error');
  }
}

class FeedbackModel{
  String user;
  String email;
  double starRate;
  String message;
  String profileId;

  FeedbackModel({required this.user,required this.email,this.starRate=0.0,required this.message,required this.profileId});

  Map<String, dynamic> toMap() {
    return {
      'username': user ,
      'email' : email,
      'star_rate': starRate, // Format date/time as string
      'message': message,
      'profile_id' : profileId
    };
  }
  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      user: map['user'],
      email: map['email'],
      starRate: map['star_rate'],
      message: map['message'] as String,
      profileId: map['profile_id']
    );
  }

}

class FiveStarRating extends StatefulWidget {


  FiveStarRating();

  @override
  _FiveStarRatingState createState() => _FiveStarRatingState();
}

class _FiveStarRatingState extends State<FiveStarRating> {
  double _starSize = 50.0;

  @override
  void initState(){
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final feedbackProvider=Provider.of<FeedbackProvider>(context);
    return ChangeNotifierProvider(create: (context) => FeedbackProvider(),builder: (context, child) => GestureDetector(
      onTapDown: (details) {
        // Calculate the rating based on tap position
        setState(() {
          feedbackProvider.star_rating=((details.localPosition.dx / _starSize + 1).clamp(0.0, 5.0)).floorToDouble();
          print(feedbackProvider.star_rating);
        });
      },
      onPanUpdate: (details) {
        // Calculate the rating based on drag position
        setState(() {
          double temp=((details.localPosition.dx / _starSize + 1).clamp(0.0, 5.0)).floorToDouble();
          feedbackProvider.star_rating=temp;

          print('${feedbackProvider.star_rating} ${temp}');
        });
      },
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
                  (index) {
                return GestureDetector(
                  onTap: () {
                    // Set the rating when tapping on a star
                    setState(() {
                      feedbackProvider.star_rating = index + 1.0;
                      print(feedbackProvider.star_rating);
                    });
                  },
                  child: Icon(
                    Icons.star,
                    size: _starSize,
                    color: index < feedbackProvider.star_rating.floor() ? Colors.yellow : Colors.grey,
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
                  (index) {
                return Container(
                  width: _starSize,
                  height: _starSize,
                  color: Colors.transparent,
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}


class FeedbackProvider extends ChangeNotifier {
  List<FeedbackModel> _feedbacks = [];
  double star_rating=0.0;



  List<FeedbackModel> get feedbacks => _feedbacks; // Getter for the meetings list


  void updateRatingValue(double value){
    star_rating=value;
    notifyListeners();
  }

  void addFeedback(FeedbackModel feedback) {
    _feedbacks.add(feedback);
    notifyListeners();
  }




}
