/*

Stack(
  children: [
    Container(
      color: theme.background.shade500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment(0, 0),
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Column(
              children: [
                Text(
                  "Authentifiziere deine Telefonnummer",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontFamily: "Space Grotesk",
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: EdgeInsets.only(top: 80),
                        child: IntlPhoneField(
                          focusNode: _phoneFocusNode,
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: "Telefonnummer",
                          ),
                          validator: (PhoneNumber? phone) {
                            if (phone == null || phone.number.isEmpty) {
                              return 'Bitte geben Sie eine Telefonnummer ein';
                            }
    
                            if (phone.isValidNumber()) {
                              numberIsValidated = true;
                              return null;
                            } else {
                              numberIsValidated = false;
                              return 'Ungültige Telefonnummer';
                            }
                          },
                          cursorColor: theme.info.shade500,
                          initialCountryCode: "DE",
                          onChanged: (phone) {
                            if (phone.isValidNumber()) {
                              setState(() {
                                tempNumberIsValid = true;
                              });
                            } else {
                              setState(() {
                                tempNumberIsValid = false;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 35),
                      Row(
                        children: [
                          Checkbox(
                            value: acceptedProcessing,
                            fillColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (!states.contains(WidgetState.selected)) {
                                return Colors.transparent;
                              } else {
                                return theme.info.shade700;
                              }
                            }),
                            checkColor: theme.info.shade300,
                            onChanged: (checked) {
                              if (checked == null) return;
    
                              _phoneFocusNode.unfocus();
                              if (checked) {
                                setState(() {
                                  acceptedProcessing = true;
                                });
                              } else {
                                setState(() {
                                  acceptedProcessing = false;
                                });
                              }
                            },
                          ),
                          Flexible(
                            child: Text(
                              "Ich bin damit einverstanden, dass die Telefonnummer für die Authentifizierung genutzt "
                              "und lokal und auf dem Server gespeichert wird.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: "Space Grotesk",
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 70),
                      GestureDetector(
                        onTap: () async {
                          if (!tempNumberIsValid || !acceptedProcessing) return;
                          _phoneFocusNode.unfocus();
    
                          if (formKey.currentState!.validate()) {
                            final String number = _controller.text.trim();
    
                            try {
                              verificationId = await sendCode(number);
    
                              if (!context.mounted) return;
                              setState(() {
                                showModal = true;
                              });
                            } catch (error) {
                              showNumberVerificationErrorSnackbar();
                            }
                          }
    
                          _onChecked();
                        },
                        child: Container(
                          width: 100,
                          padding: EdgeInsets.only(
                            top: 10,
                            left: 20,
                            bottom: 10,
                            right: 20,
                          ),
                          decoration: BoxDecoration(
                            color: tempNumberIsValid && acceptedProcessing
                                ? theme.background.shade300
                                : theme.background.shade400,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            "Prüfen",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Space Grotesk",
                              fontSize: 15,
                              color: tempNumberIsValid && acceptedProcessing
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
);

Positioned.fill(
  child: Stack(
    children: [
      Container(
        color: Colors.black.withAlpha(200),
      ),
      Center(
        child: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: theme.background.shade600,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Geben Sie den SMS-Code ein:"),
              SizedBox(height: 20),
              TextField(
                maxLength: 6,
                controller: codeController,
                decoration: InputDecoration(),
                onChanged: (value) {
                  if (value.length == 6) {
                    setState(() {
                      codeValid = true;
                    });
                  }
                  else {
                    setState(() {
                      codeValid = false;
                    });
                  }
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => showModal = false);
                    },
                    child: Text(
                      "Schließen"
                    ),
                  ),
                  ElevatedButton(
                    onPressed: codeValid ? () async {
                      PhoneAuthCredential credential = PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: codeController.text.trim(),
                      );
                      
                      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                      setState(() => showModal = false);
                    } : null,
                    child: Text(
                      "Abschicken"
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ],
  ),
)

*/