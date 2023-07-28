// Update this variable to point to your domain.
//var apigatewayendpoint = 'https://3ijkgfpwxf.execute-api.ap-northeast-1.amazonaws.com/search';
var apigatewayendpoint = 'https://epl65c6lr1.execute-api.us-east-1.amazonaws.com/opensearchapi-test'
var loadingdiv = $('#loading');
var noresults = $('#noresults');
var resultdiv = $('#results');
var searchbox = $('input#search');
var timer = 0;

// Executes the search function 250 milliseconds after user stops typing
searchbox.keyup(function () {
  clearTimeout(timer);
  timer = setTimeout(search, 250);
});

async function search() {
  // Clear results before searching
  noresults.hide();
  resultdiv.empty();
  loadingdiv.show();
  // Get the query from the user
  let query = searchbox.val();
  // Only run a query if the string contains at least three characters
  if (query.length > 2) {
    // Make the HTTP request with the query as a parameter and wait for the JSON results
    let response = await $.get(apigatewayendpoint, { q: query, size: 25 }, 'json');
    response_json=JSON.parse(response);
 
    // Get the part of the JSON response that we care about
    let results = response_json.hits.hits[0];
    console.log('JSON Response is',response_json);
    let Author = response_json.hits.hits[0]._source.Author;
    console.log('Author is',Author);
    console.log('Results is',results);
    console.log('Type of results is ', (typeof results))
    console.log('Results Length is', results.length);
    /*
    if (results.length > 0) {
      loadingdiv.hide();
      // Iterate through the results and write them to HTML
      resultdiv.append('<p>Found ' + results.length + ' results.</p>');
      for (var item in results) {
        let author = results[item]._source.Author;
        let date = results[item]._source.Date;
        let body = results[item]._source.Body;
        // Construct the full HTML string that we want to append to the div
        resultdiv.append('<div class="result">' +
        '<div><h2><a href="' + author + '">' + date + '</a></h2><p>' + body + '</p></div></div>');
      }
    } else {
      noresults.show();
    }
    */
  let author = response_json.hits.hits[0]._source.Author;
  let date = response_json.hits.hits[0]._source.Date;
  let body = response_json.hits.hits[0]._source.Body;
        // Construct the full HTML string that we want to append to the div
  resultdiv.append(' <div><b>Author</b>:</div>'+author+ '<div>Date:</div>'+date+' <div>Body:</div>'+body);
  }
  loadingdiv.hide();
}

// Tiny function to catch images that fail to load and replace them
function imageError(image) {
  image.src = 'images/no-image.png';
}
