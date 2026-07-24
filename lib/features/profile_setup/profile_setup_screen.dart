import 'package:flutter/material.dart';
import '../camera/camera_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int currentStep = 0;

  final ageController = TextEditingController();
  final cigarettesController = TextEditingController();
  final smokingYearsController = TextEditingController();

  String gender = "";
  String smokingStatus = "";
  String primaryType = "";

  String alcohol = "";
  String water = "";
  String brushing = "";

  Set<String> symptoms = {};

  double pain = 3;
  double irritation = 5;

  bool get showSmokingDetails =>
      smokingStatus == "Yes" || smokingStatus == "Occasionally";

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void nextStep() {
    // STEP 1 VALIDATION
    if (currentStep == 0) {
      if (ageController.text.trim().isEmpty) {
        showError("Please enter age");
        return;
      }

      if (gender.isEmpty) {
        showError("Please select gender");
        return;
      }
    }

    // STEP 2 VALIDATION
    if (currentStep == 1) {
      if (smokingStatus.isEmpty) {
        showError("Please select smoking status");
        return;
      }

      if (showSmokingDetails) {
        if (primaryType.isEmpty) {
          showError("Please select smoking type");
          return;
        }

        if (cigarettesController.text.trim().isEmpty) {
          showError("Enter cigarettes per day");
          return;
        }

        if (smokingYearsController.text.trim().isEmpty) {
          showError("Enter smoking years");
          return;
        }
      }
    }

    // STEP 3 VALIDATION
    if (currentStep == 2) {
      if (symptoms.isEmpty) {
        showError("Select at least one symptom");
        return;
      }
    }

    // STEP 4 VALIDATION
    if (currentStep == 3) {
      if (alcohol.isEmpty || water.isEmpty || brushing.isEmpty) {
        showError("Please complete lifestyle factors");
        return;
      }
    }

    // NAVIGATION
    if (currentStep < 4) {
      setState(() => currentStep++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );
    }
  }

  void backStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              Row(
                children: [
                  if (currentStep > 0)
                    IconButton(
                      onPressed: backStep,
                      icon: const Icon(Icons.arrow_back),
                    ),

                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentStep + 1) / 5,
                      color: Colors.teal,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text("Step ${currentStep + 1} of 5"),
                ],
              ),

              const SizedBox(height: 25),

              Expanded(child: SingleChildScrollView(child: buildStep())),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),

                  onPressed: nextStep,

                  child: Text(
                    currentStep == 4 ? "Complete Setup" : "Continue",

                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStep() {
    switch (currentStep) {
      case 0:
        return basicStep();

      case 1:
        return smokingStep();

      case 2:
        return symptomsStep();

      case 3:
        return lifestyleStep();

      case 4:
        return severityStep();

      default:
        return basicStep();
    }
  }

  // STEP 1
  Widget basicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Basic Information",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          "Let’s start with a few details about you",
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 25),

        const Text("Age"),

        const SizedBox(height: 8),

        TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: input("e.g. 35"),
        ),

        const SizedBox(height: 25),

        const Text("Gender"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,

          children: ["Male", "Female", "Other", "Prefer not to say"]
              .map((e) => pill(e, gender, (v) => setState(() => gender = v)))
              .toList(),
        ),
      ],
    );
  }

  // STEP 2
  Widget smokingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Smoking History",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          "This helps AI understand your recovery",
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 25),

        const Text("Do you smoke?"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,

          children: ["Yes", "No", "Occasionally"]
              .map(
                (e) => pill(e, smokingStatus, (v) {
                  setState(() {
                    smokingStatus = v;

                    if (v == "No") {
                      primaryType = "";
                      cigarettesController.clear();
                      smokingYearsController.clear();
                    }
                  });
                }),
              )
              .toList(),
        ),

        if (showSmokingDetails) ...[
          const SizedBox(height: 25),

          const Text("Primary Type"),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: primaryType.isEmpty ? null : primaryType,

            decoration: input("Select type"),

            items: [
              "Cigarettes",
              "Vape",
              "Cigars",
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),

            onChanged: (v) {
              setState(() {
                primaryType = v ?? "";
              });
            },
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cigarettesController,
                  keyboardType: TextInputType.number,
                  decoration: input("Per day"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: TextField(
                  controller: smokingYearsController,
                  keyboardType: TextInputType.number,
                  decoration: input("Years"),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // STEP 3
  Widget symptomsStep() {
    final items = [
      "Redness",
      "White patches",
      "Pain",
      "Dryness",
      "Burning sensation",
      "Bleeding",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Oral Symptoms",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          "Select all that apply",
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((e) => chip(e)).toList(),
        ),
      ],
    );
  }

  // STEP 4
  Widget lifestyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Lifestyle Factors",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        const Text("Alcohol Usage"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,

          children: ["None", "Light", "Heavy"]
              .map((e) => pill(e, alcohol, (v) => setState(() => alcohol = v)))
              .toList(),
        ),

        const SizedBox(height: 20),

        const Text("Water Intake"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,

          children: ["<1L", "1-2L", ">2L"]
              .map((e) => pill(e, water, (v) => setState(() => water = v)))
              .toList(),
        ),

        const SizedBox(height: 20),

        const Text("Brushing Frequency"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          runSpacing: 10,

          children: ["1x", "2x", "3x+"]
              .map(
                (e) => pill(e, brushing, (v) => setState(() => brushing = v)),
              )
              .toList(),
        ),
      ],
    );
  }

  // STEP 5
  Widget severityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Severity",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        Text("Pain Level ${pain.toInt()}/10"),

        Slider(
          value: pain,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: Colors.teal,
          onChanged: (v) => setState(() => pain = v),
        ),

        const SizedBox(height: 20),

        Text("Irritation ${irritation.toInt()}/10"),

        Slider(
          value: irritation,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: Colors.teal,
          onChanged: (v) => setState(() => irritation = v),
        ),
      ],
    );
  }

  // UI COMPONENTS

  Widget pill(String text, String selected, Function(String) onTap) {
    final active = selected == text;

    return GestureDetector(
      onTap: () => onTap(text),

      child: Container(
        constraints: const BoxConstraints(minWidth: 90),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(
          color: active ? Colors.teal : Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: active ? Colors.teal : Colors.grey.shade300,
          ),
        ),

        child: Text(
          text,
          textAlign: TextAlign.center,

          style: TextStyle(color: active ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget chip(String text) {
    final selected = symptoms.contains(text);

    return GestureDetector(
      onTap: () {
        setState(() {
          selected ? symptoms.remove(text) : symptoms.add(text);
        });
      },

      child: Container(
        constraints: const BoxConstraints(minWidth: 130),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: selected ? Colors.teal : Colors.grey.shade300,
          ),
        ),

        child: Text(
          text,

          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,

      filled: true,
      fillColor: Colors.grey[100],

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
