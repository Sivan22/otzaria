import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';


class mySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
           body: Container(
      child: SettingsScreen(
        title: 'הגדרות',
        children: [
          SettingsGroup(
            title: 'הגדרות גופן',            
            children: <Widget>[
              SliderSettingsTile(
                title: 'גודל גופן בספר',
                settingKey: 'key-font-size',
                defaultValue: 20,
                min: 15,
                max: 50,
                step: 1,
                leading: Icon(Icons.font_download),
                decimalPrecision: 0,                
                onChange: (value) { 
                  
                      },
              ),
              DropDownSettingsTile<String>(
  title: 'גופן',
  settingKey: 'key-font-family',
  values: <String, String>{
    'David': 'דוד',
    'Arial': 'אריאל',
    'Candara': 'קנדרה',
    'roboto': 'רובוטו',
    'Calibri': 'קליברי',
  },
  selected: 'David',
  onChange: (value) {
    debugPrint('key-dropdown-email-view: $value');
  },
)
                ],
          ),
          
        ],
      ),
    )
      );
  }
  }