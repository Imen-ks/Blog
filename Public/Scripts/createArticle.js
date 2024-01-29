$.ajax({
  url: "/api/tags/",
  type: "GET",
  contentType: "application/json; charset=utf-8"
}).then(function (response) {
  var dataToReturn = [];
  for (var i=0; i < response.length; i++) {
    var tagToTransform = response[i];
    var newTag = {
        id: tagToTransform["name"],
        text: tagToTransform["name"]
    };
    dataToReturn.push(newTag);
  }
  $("#tags").select2({
    placeholder: "Select Tags for the Article",
    tags: true,
    tokenSeparators: [','],
    data: dataToReturn
  });
});
