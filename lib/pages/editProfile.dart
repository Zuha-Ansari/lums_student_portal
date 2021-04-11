import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lums_student_portal/backend/validators.dart';
import 'package:lums_student_portal/models/profile.dart';
import 'package:lums_student_portal/themes/progessIndicator.dart';
import 'package:intl/date_symbol_data_file.dart'; // for DateFormat

class EditProfile extends StatefulWidget {
  final bool showSC;
  final String userId;
  EditProfile({required this.showSC, required this.userId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _EditProfileState extends State<EditProfile> {
  late ProfileModel _profile;
  late bool objectInitialized;
  late Future<DocumentSnapshot?> _future;
  FirebaseFirestore _db = FirebaseFirestore.instance;
  final filePicker = FilePicker.platform;
  final _formKey = GlobalKey<FormState>();

  void initState() {
    _future = _db.collection("Profiles").doc(widget.userId).get();
    _profile = ProfileModel(name: '', role: 'Student', email: '');
    objectInitialized = false;
    super.initState();
  }

  TimeOfDay? selectedTime;
  OfficeHours? selectedOfficeHours;

  void deleteProfilePicture(String docID) async {
    String result = '';
    if (_profile.pictureURL != null) {
      result = await _profile.deletePicture(docID);
    } else {
      result = "You currently don't have a profile picture!";
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: <Widget>[
      Icon(
        Icons.notification_important,
        color: Colors.white,
        semanticLabel: "Done",
      ),
      Text('  $result')
    ])));
  }

  void update(String docID) async {
    if (_formKey.currentState!.validate()) {
      print(_profile.name);
      String result = await _profile.updateDb(docID);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: <Widget>[
        Icon(
          Icons.notification_important,
          color: Colors.white,
          semanticLabel: "Done",
        ),
        Text('  $result')
      ])));
    }
  }

  void selectPicture() async {
    print("select picture called");
    FilePickerResult? result = await filePicker
        .pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png']);
    // ignore: unnecessary_null_comparison
    if (result != null) {
      _profile.image = File(result.paths[0]!);
      print(_profile.image);
      setState(() {
        _profile.pictureChanged = true;
      });
    } else {
      setState(() {
        _profile.pictureChanged = false;
      });
    }
  }

  void formatTime() {
    selectedOfficeHours!.days == "MW"
        ? selectedOfficeHours!.days = "Mondays and Wednesdays"
        : selectedOfficeHours!.days == "TT"
            ? selectedOfficeHours!.days = "Tuesdays and Thursdays"
            : selectedOfficeHours!.days == "WF"
                ? selectedOfficeHours!.days = "Wednesdays and Fridays"
                : selectedOfficeHours!.days = "None";
    selectedOfficeHours!.time = selectedTime!.hourOfPeriod.toString() +
        ":" +
        (selectedTime!.minute.toString().length == 1? "0"+selectedTime!.minute.toString(): selectedTime!.minute.toString()) +
        " " +
        selectedTime!.period.toString().substring(10).toUpperCase();
  }

  TimeOfDay timeConvert(String normTime) { // converts from '6:00 AM' to TimeOfDay object
    // source: https://stackoverflow.com/questions/53382971/how-to-convert-string-to-timeofday-in-flutter
    int hour;
    int minute;
    String ampm = normTime.substring(normTime.length - 2);
    String result = normTime.substring(0, normTime.indexOf(' '));
    if (ampm == 'AM' && int.parse(result.split(":")[1]) != 12) {
      hour = int.parse(result.split(':')[0]);
      if (hour == 12) hour = 0;
      minute = int.parse(result.split(":")[1]);
    } else {
      hour = int.parse(result.split(':')[0]) - 12;
      if (hour <= 0) {
        hour = 24 + hour;
      }
      minute = int.parse(result.split(":")[1]);
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  void initTimeandOfficeHoursObjs() {
    if (_profile.officeHoursNull()) {
      selectedOfficeHours = null;
    }
    else {
      selectedOfficeHours = new OfficeHours(_profile.officeHours!['days'], _profile.officeHours!['time']);
      selectedOfficeHours!.days == "Mondays and Wednesdays"
          ? selectedOfficeHours!.days = "MW"
          : selectedOfficeHours!.days == "Tuesdays and Thursdays"
              ? selectedOfficeHours!.days = "TT"
              : selectedOfficeHours!.days == "Wednesdays and Fridays"
                  ? selectedOfficeHours!.days = "WF"
                  : selectedOfficeHours!.days = "None";
      
      selectedTime = timeConvert(selectedOfficeHours!.time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors
                .black, //Changing back button's color to black so that its visible. TODO: text button instead of <- icon?
          ),
          title: Text('Edit Profile',
              style: Theme.of(context).textTheme.headline6),
          backgroundColor: Colors.white,
        ),
        body: FutureBuilder<DocumentSnapshot?>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<DocumentSnapshot?> snapshot) {
            if (snapshot.hasData) {
              //print(snapshot.data!['residence_status']);
              //return (Text("Done"));
              if (!objectInitialized) {
                _profile.convertToObject(snapshot.data!);
                initTimeandOfficeHoursObjs();
                objectInitialized = true;
              }
              return SafeArea(
                  minimum: EdgeInsets.fromLTRB(30, 10, 30, 30),
                  child: SingleChildScrollView(
                    child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // TODO: Add discard/confirmation dialog box when going back. WillPopScope class might be useful.
                            SizedBox(height: 15),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 10,
                                      color: Colors.black38,
                                      spreadRadius: 5)
                                ],
                              ),
                              child: InkWell(
                                // Profile Photo
                                //InkWell is similar to GestureDetector but it also has an animation
                                onTap: () async {
                                  return showDialog<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        // titleTextStyle: ,
                                        title: Text('Profile Picture',
                                            textAlign: TextAlign.center),
                                        content: SingleChildScrollView(
                                          child: ListBody(
                                            children: <Widget>[
                                              ListTile(
                                                  leading: new Icon(Icons
                                                      .add_photo_alternate_outlined),
                                                  title: Text('Upload a Photo'),
                                                  onTap: () => {
                                                        selectPicture(),
                                                        Navigator.pop(context),
                                                      }),
                                              ListTile(
                                                  leading: new Icon(Icons
                                                      .highlight_remove_sharp),
                                                  title: Text(
                                                      'Remove Current Photo'),
                                                  onTap: () => {
                                                        deleteProfilePicture(
                                                            snapshot.data!.id),
                                                        Navigator.pop(context),
                                                      }),
                                            ],
                                          ),
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            style: TextButton.styleFrom(
                                                primary: Colors.redAccent),
                                            child: Text('Cancel'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              // setState(() {});
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: CircleAvatar(
                                    radius: 80 + 4, // the profile avatar border
                                    backgroundColor: Colors.white,
                                    child: _profile.pictureChanged
                                        ? CircleAvatar(
                                            backgroundImage:
                                                FileImage(_profile.image!),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                      blurRadius: 15,
                                                      color: Colors.black87,
                                                      spreadRadius: 5)
                                                ],
                                              ),
                                              child: new Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.grey,
                                            radius: 80,
                                          )
                                        : _profile.pictureURL == null
                                            ? CircleAvatar(
                                                backgroundImage: AssetImage(
                                                    "assets/default-avatar.png"),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                          blurRadius: 15,
                                                          color: Colors.black87,
                                                          spreadRadius: 5)
                                                    ],
                                                  ),
                                                  child: new Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: Colors.grey,
                                                radius: 80,
                                              )
                                            : CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    _profile.pictureURL!),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                          blurRadius: 15,
                                                          color: Colors.black87,
                                                          spreadRadius: 5)
                                                    ],
                                                  ),
                                                  child: new Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                radius: 80,
                                                backgroundColor: Colors.grey,
                                              )),
                              ),
                            ),
                            SizedBox(height: 25),
                            TextFormField(
                              initialValue: _profile.name,
                              decoration: InputDecoration(labelText: "Name"),
                              validator: (val) => headingValidator(val!),
                              onChanged: (val) {
                                setState(() => _profile.name = val);
                              },
                            ),
                            SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: DropdownButtonFormField<String>(
                                hint: Text("Hostel Status"),
                                value: _profile.hostel,
                                icon: const Icon(Icons.arrow_drop_down),
                                style: Theme.of(context)
                                    .inputDecorationTheme
                                    .labelStyle, // to match the style with textfields
                                onChanged: (newVal) {
                                  setState(() {
                                    _profile.hostel = newVal.toString();
                                  });
                                },
                                items: _profile.residenceTypes
                                    .map<DropdownMenuItem<String>>((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: DropdownButtonFormField<String>(
                                hint: Text("Year"),
                                value: _profile.year,
                                icon: const Icon(Icons.arrow_drop_down),
                                style: Theme.of(context)
                                    .inputDecorationTheme
                                    .labelStyle, // to match the style with textfields
                                onChanged: (newVal) {
                                  setState(() {
                                    _profile.year = newVal.toString();
                                  });
                                },
                                items: _profile.years
                                    .map<DropdownMenuItem<String>>((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 15),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: DropdownButtonFormField<String>(
                                hint: Text("School"),
                                value: _profile.school,
                                icon: const Icon(Icons.arrow_drop_down),
                                style: Theme.of(context)
                                    .inputDecorationTheme
                                    .labelStyle, // to match the style with textfields
                                onChanged: (newVal) {
                                  setState(() {
                                    _profile.school = newVal.toString();
                                  });
                                },
                                items: _profile.schools
                                    .map<DropdownMenuItem<String>>((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              initialValue: _profile.major,
                              decoration: InputDecoration(labelText: "Major"),
                              validator: (val) => headingValidator(val!),
                              onChanged: (val) {
                                setState(() => _profile.major = val);
                              },
                            ),
                            (_profile.role == "SC" || _profile.role == "IT")
                                ? SizedBox(height: 0)
                                : SizedBox(height: 15),
                            if (_profile.role == "SC" || _profile.role == "IT")
                              Text(
                                "Select Office Hours Days:",
                                style: TextStyle(height: 5, fontSize: 15),
                              ),
                            if (_profile.role == "SC" || _profile.role == "IT")
                              Wrap(spacing: 8.0, children: <Widget>[
                                FilterChip(
                                  label: Text('Mon-Wed'),
                                  selected: selectedOfficeHours!.days == "MW"
                                      ? true
                                      : false,
                                  selectedColor: Theme.of(context).primaryColor,
                                  onSelected: (bool value) {
                                    setState(() {
                                      selectedOfficeHours!.days == "MW"
                                          ? selectedOfficeHours!.days = "None"
                                          : selectedOfficeHours!.days = "MW";
                                    });
                                  },
                                ),
                                FilterChip(
                                  label: Text('Tues-Thurs'),
                                  selected: selectedOfficeHours!.days == "TT"
                                      ? true
                                      : false,
                                  selectedColor: Theme.of(context).primaryColor,
                                  onSelected: (bool value) {
                                    setState(() {
                                      selectedOfficeHours!.days == "TT"
                                          ? selectedOfficeHours!.days = "None"
                                          : selectedOfficeHours!.days = "TT";
                                    });
                                  },
                                ),
                                FilterChip(
                                  label: Text('Wed-Fri'),
                                  selected: selectedOfficeHours!.days == "WF"
                                      ? true
                                      : false,
                                  selectedColor: Theme.of(context).primaryColor,
                                  onSelected: (bool value) {
                                    setState(() {
                                      selectedOfficeHours!.days == "WF"
                                          ? selectedOfficeHours!.days = "None"
                                          : selectedOfficeHours!.days = "WF";
                                    });
                                  },
                                ),
                              ]),

                            if (_profile.role == "SC" || _profile.role == "IT")
                              SizedBox(height: 15),

                            if (_profile.role == "SC" || _profile.role == "IT")
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Theme.of(context)
                                        .inputDecorationTheme
                                        .fillColor,
                                    textStyle: Theme.of(context)
                                        .inputDecorationTheme
                                        .labelStyle,
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Office hours timeslot",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  onPressed: () async {
                                    selectedTime = await showTimePicker(
                                      context: context,
                                      initialTime: selectedTime != null? selectedTime!: TimeOfDay.now(),
                                      builder: (BuildContext? context,
                                          Widget? child) {
                                        return MediaQuery(
                                          data: MediaQuery.of(context!)
                                              .copyWith(
                                                  alwaysUse24HourFormat: false),
                                          child: child!,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            if (_profile.role == "SC" || _profile.role == "IT")
                              SizedBox(height: 15),

                            if (_profile.role == "SC" || _profile.role == "IT")
                              TextFormField(
                                initialValue: _profile.manifesto,
                                maxLines: null,
                                decoration:
                                    InputDecoration(labelText: "Manifesto"),
                                // validator: (val) => headingValidator(val!), // 30 characters limit not needed for manifesto
                                onChanged: (val) {
                                  setState(() => _profile.manifesto = val);
                                },
                              ),
                            if (_profile.role == "SC" || _profile.role == "IT")
                              SizedBox(height: 15),
                            
                            SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () => {
                                    if (_profile.role != "Student")
                                      {
                                        formatTime(),
                                        _profile.officeHours =
                                            selectedOfficeHours!.toMap(),
                                      },
                                    update(snapshot.data!.id)
                                  },
                                  child: Text('Update Profile',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                ),
                              ),
                            SizedBox(height: 15),
                            // TODO: Add progress indicator after pressing update button
                          ],
                        )),
                  ));
            } else if (snapshot.hasError) {
              return Text("Error");
            } else {
              return LoadingScreen();
            }
          },
        ));
  }
}

/*String residenceSelection = 'Select Residence Status';
  String yearSelection = 'Select Your Year';
  String schoolSelection = 'Select Your School';
  String schoolOfficeHoursDay = 'Select Office Hours Day';*/
/*
Form(
// TODO: Backend part not done
child: SingleChildScrollView(
child: SafeArea(
minimum: EdgeInsets.all(30),
child: Column(children: <Widget>[
DropdownButtonFormField<String>(
value: yearSelection,
icon: const Icon(Icons.arrow_drop_down),
style: Theme.of(context).inputDecorationTheme.labelStyle, // to match the style with textfields
onChanged: (String? newValue) {
setState(() {
yearSelection = newValue!;
});
},
items: <String>['Select Your Year','First-Year', 'Sophomore', 'Junior', 'Senior', 'Fifth-Year']
.map<DropdownMenuItem<String>>((String value) {
return DropdownMenuItem<String>(
value: value,
child: Text(value),
);
}).toList(),
),
SizedBox(height: 15),
DropdownButtonFormField<String>(
value: residenceSelection,
icon: const Icon(Icons.arrow_drop_down),
style: Theme.of(context).inputDecorationTheme.labelStyle, // to match the style with textfields
onChanged: (String? newValue) {
setState(() {
residenceSelection = newValue!;
});
},
items: <String>['Select Residence Status','Hostelite', 'Day Scholar']
.map<DropdownMenuItem<String>>((String value) {
return DropdownMenuItem<String>(
value: value,
child: Text(value),
);
}).toList(),
),
SizedBox(height: 15),
DropdownButtonFormField<String>(
value: schoolSelection,
icon: const Icon(Icons.arrow_drop_down),
style: Theme.of(context).inputDecorationTheme.labelStyle, // to match the style with textfields
onChanged: (String? newValue) {
setState(() {
schoolSelection = newValue!;
});
},
items: <String>['Select Your School', 'MGSHSS', 'SAHSOL', 'SBASSE', 'SDSB', 'SOE']
.map<DropdownMenuItem<String>>((String value) {
return DropdownMenuItem<String>(
value: value,
child: Text(value),
);
}).toList(),
),
SizedBox(height: 15),
if (showSC)
DropdownButtonFormField<String>(
value: schoolOfficeHoursDay,
icon: const Icon(Icons.arrow_drop_down),
style: Theme.of(context).inputDecorationTheme.labelStyle, // to match the style with textfields
onChanged: (String? newValue) {
setState(() {
yearSelection = newValue!;
});
},
items: <String>['Select Office Hours Day','Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
.map<DropdownMenuItem<String>>((String value) {
return DropdownMenuItem<String>(
value: value,
child: Text(value),
);
}).toList(),
),
if (showSC) SizedBox(height: 15),
if (showSC)
SizedBox(
// Confirm Button
width: double.infinity,
height: 40,
child: ElevatedButton (
child: Text("Office hours timeslot"),
onPressed: () async {
selectedTime = await showTimePicker(
context: context,
initialTime: TimeOfDay.now(),
builder: (BuildContext? context, Widget? child) {
return MediaQuery(
data: MediaQuery.of(context!)
    .copyWith(alwaysUse24HourFormat: false),
child: child!,
);
},
);
},
),
),
if (showSC) SizedBox(height: 15),
if (showSC)
TextFormField(
decoration: InputDecoration(labelText: "Manifesto"),
maxLines: null,
),
if (showSC) SizedBox(height: 15),
SizedBox(
// Confirm Button
width: double.infinity,
height: 40,
child: ElevatedButton(
// onPressed: () => validate(),
onPressed: () => {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
content: Row(children: <Widget>[
Icon(
Icons.error,
color: Colors.white,
semanticLabel: "Error",
),
Text('TODO: Backend part not done')
])))
},
child: Text('Confirm',
style: Theme.of(context).textTheme.headline5),
),
),
]),
),
),
),*/
