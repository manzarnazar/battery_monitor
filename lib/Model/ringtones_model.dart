class Ringtone {
  final String name;
  final String filePath;
  bool isSelected;

  Ringtone(
      {required this.name, required this.filePath, required this.isSelected});
}

List<Ringtone> ringtonesList = [
  Ringtone(
      isSelected: false,
      name: 'Car Honk',
      filePath: 'assets/ringtones/car_honk.mp3'),
  Ringtone(
      isSelected: false,
      name: 'Cat Meowing',
      filePath: 'assets/ringtones/cat_meowing.mp3'),
  Ringtone(
      isSelected: false,
      name: 'Cavalry',
      filePath: 'assets/ringtones/cavalry.mp3'),
  Ringtone(
      isSelected: false,
      name: 'Dog Barking',
      filePath: 'assets/ringtones/dog_barking.mp3'),
  Ringtone(
      isSelected: false,
      name: 'Door Bell',
      filePath: 'assets/ringtones/door_bell.mp3'),
  Ringtone(
      isSelected: false,
      name: 'Hello',
      filePath: 'assets/ringtones/hello.mp3'),
  Ringtone(
      isSelected: false,
      name: 'Party Horn',
      filePath: 'assets/ringtones/party_horn.mp3'),
  Ringtone(
      isSelected: false,
      name: 'police Whistle',
      filePath: 'assets/ringtones/police_whistle.mp3'),
  Ringtone(
      isSelected: false,
      name: 'whistle',
      filePath: 'assets/ringtones/whistle.mp3'),
];
