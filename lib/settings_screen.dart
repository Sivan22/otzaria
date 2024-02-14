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
                title: 'גודל גופן התחלתי בספרים',
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
  values: const <String, String>{
    'DavidLibre': 'דוד',
    'Arial': 'אריאל',
    'FrankRuhlLibre':'פרנק-רוהל',
    'BonaNova': 'בונה-נובה',
    'NotoRashiHebrew': 'רש"י',
    'NotoSerifHebrew': 'נוטו',
    'Tinos': 'טינוס',
    'Rubik':'רוביק',
    'Candara': 'קנדרה',
    'roboto': 'רובוטו',
    'Calibri': 'קליברי',

  },
  selected: 'FrankRuhlLibre',
  onChange: (value) {
  },
),
              DropDownSettingsTile<String>(
  title: 'עובי',
  settingKey: 'key-font-weight',
  values: const <String, String>{
    'normal':'רגיל',
    'w600':'בינוני',
    'bold':'עבה',
  },
  selected:'normal',
  onChange: (value) {
  },
),
                ],
          ),
          
        ],
      ),
    )
      );
  }
  }