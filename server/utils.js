

module.exports.makeId = function makeid(length) {
  var result = "";
  var characters =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  var charactersLength = characters.length;
  for (var i = 0; i < length; i++) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
}

module.exports.makeSnailId = function makeSnailid(length) {
  var result = "";
  var vocals = "AEIOU";
  var vocalLength = vocals.length;
  var nonvocals = "BCDFGHJKLMNPQRSTVWXZ";
  var nonvocalLength = nonvocals.length;
  for (var i = 0; i < length; i++) {
    result = nonvocals.charAt(Math.floor(Math.random() * nonvocalLength )) + vocals.charAt(Math.floor(Math.random() * vocalLength)) + nonvocals.charAt(Math.floor(Math.random() * nonvocalLength)) + "Y";
  }
  return result;
}