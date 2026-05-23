import '../models/models.dart';

List<StateData> buildInitialStates() {
  return [
    StateData(name: 'Tennessee', code: 'TN', counties: _tnCounties()),
    StateData(name: 'Kentucky', code: 'KY', counties: _kyCounties()),
    StateData(name: 'West Virginia', code: 'WV', counties: _wvCounties()),
  ];
}

List<County> _tnCounties() {
  const names = [
    'Anderson', 'Bedford', 'Benton', 'Bledsoe', 'Blount', 'Bradley',
    'Campbell', 'Cannon', 'Carroll', 'Carter', 'Cheatham', 'Chester',
    'Claiborne', 'Clay', 'Cocke', 'Coffee', 'Crockett', 'Cumberland',
    'Davidson', 'Decatur', 'DeKalb', 'Dickson', 'Dyer', 'Fayette',
    'Fentress', 'Franklin', 'Gibson', 'Giles', 'Grainger', 'Greene',
    'Grundy', 'Hamblen', 'Hamilton', 'Hancock', 'Hardeman', 'Hardin',
    'Hawkins', 'Haywood', 'Henderson', 'Henry', 'Hickman', 'Houston',
    'Humphreys', 'Jackson', 'Jefferson', 'Johnson', 'Knox', 'Lake',
    'Lauderdale', 'Lawrence', 'Lewis', 'Lincoln', 'Loudon', 'Macon',
    'Madison', 'Marion', 'Marshall', 'Maury', 'McMinn', 'McNairy',
    'Meigs', 'Monroe', 'Montgomery', 'Moore', 'Morgan', 'Obion',
    'Overton', 'Perry', 'Pickett', 'Polk', 'Putnam', 'Rhea',
    'Roane', 'Robertson', 'Rutherford', 'Scott', 'Sequatchie', 'Sevier',
    'Shelby', 'Smith', 'Stewart', 'Sullivan', 'Sumner', 'Tipton',
    'Trousdale', 'Unicoi', 'Union', 'Van Buren', 'Warren', 'Washington',
    'Wayne', 'Weakley', 'White', 'Williamson', 'Wilson',
  ];
  return names.map((n) => County(name: n, stateCode: 'TN')).toList();
}

List<County> _kyCounties() {
  const names = [
    'Adair', 'Allen', 'Anderson', 'Ballard', 'Barren', 'Bath',
    'Bell', 'Boone', 'Bourbon', 'Boyd', 'Boyle', 'Bracken',
    'Breathitt', 'Breckinridge', 'Bullitt', 'Butler', 'Caldwell', 'Calloway',
    'Campbell', 'Carlisle', 'Carroll', 'Carter', 'Casey', 'Christian',
    'Clark', 'Clay', 'Clinton', 'Crittenden', 'Cumberland', 'Daviess',
    'Edmonson', 'Elliott', 'Estill', 'Fayette', 'Fleming', 'Floyd',
    'Franklin', 'Fulton', 'Gallatin', 'Garrard', 'Grant', 'Graves',
    'Grayson', 'Green', 'Greenup', 'Hancock', 'Hardin', 'Harlan',
    'Harrison', 'Hart', 'Henderson', 'Henry', 'Hickman', 'Hopkins',
    'Jackson', 'Jefferson', 'Jessamine', 'Johnson', 'Kenton', 'Knott',
    'Knox', 'Larue', 'Laurel', 'Lawrence', 'Lee', 'Leslie',
    'Letcher', 'Lewis', 'Lincoln', 'Livingston', 'Logan', 'Lyon',
    'Madison', 'Magoffin', 'Marion', 'Marshall', 'Martin', 'Mason',
    'McCracken', 'McCreary', 'McLean', 'Meade', 'Menifee', 'Mercer',
    'Metcalfe', 'Monroe', 'Montgomery', 'Morgan', 'Muhlenberg', 'Nelson',
    'Nicholas', 'Ohio', 'Oldham', 'Owen', 'Owsley', 'Pendleton',
    'Perry', 'Pike', 'Powell', 'Pulaski', 'Robertson', 'Rockcastle',
    'Rowan', 'Russell', 'Scott', 'Shelby', 'Simpson', 'Spencer',
    'Taylor', 'Todd', 'Trigg', 'Trimble', 'Union', 'Warren',
    'Washington', 'Wayne', 'Webster', 'Whitley', 'Wolfe', 'Woodford',
  ];
  return names.map((n) => County(name: n, stateCode: 'KY')).toList();
}

List<County> _wvCounties() {
  const names = [
    'Barbour', 'Berkeley', 'Boone', 'Braxton', 'Brooke', 'Cabell',
    'Calhoun', 'Clay', 'Doddridge', 'Fayette', 'Gilmer', 'Grant',
    'Greenbrier', 'Hampshire', 'Hancock', 'Hardy', 'Harrison', 'Jackson',
    'Jefferson', 'Kanawha', 'Lewis', 'Lincoln', 'Logan', 'Marion',
    'Marshall', 'Mason', 'McDowell', 'Mercer', 'Mineral', 'Mingo',
    'Monongalia', 'Monroe', 'Morgan', 'Nicholas', 'Ohio', 'Pendleton',
    'Pleasants', 'Pocahontas', 'Preston', 'Putnam', 'Raleigh', 'Randolph',
    'Ritchie', 'Roane', 'Summers', 'Taylor', 'Tucker', 'Tyler',
    'Upshur', 'Wayne', 'Webster', 'Wetzel', 'Wirt', 'Wood',
    'Wyoming',
  ];
  return names.map((n) => County(name: n, stateCode: 'WV')).toList();
}
