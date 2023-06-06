import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:movies/helpers/debouncer.dart';
import '../models/models.dart';

class MoviesProvider extends ChangeNotifier {
  final String _apiKey = '944b044589d34515735dc4f547f5154c';
  final String _baseUrl = 'api.themoviedb.org';
  final String _language = 'es-ES';
  int popularPage = 0;
  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];
  Map<int, List<Cast>> moviesCast = {};
  final debouncer = Debouncer(duration: Duration(milliseconds: 500),
  onValue: (value) {
    
  },);
  final StreamController<List<Movie>> _suggestionStreamController = StreamController.broadcast();
  Stream<List<Movie>> get suggestionStream => _suggestionStreamController.stream;
  MoviesProvider() {    
    getOnDisplayMovies();
    getPopularMovies();
  }
  getOnDisplayMovies() async {    
    final response = await _getJsonData('3/movie/now_playing');
    final nowPlayingResponse = NowPlayingResponse.fromJson(response);
    onDisplayMovies = nowPlayingResponse.results;
    notifyListeners(); 
  }

  getPopularMovies() async {   
    popularPage ++; 
    final response = await  _getJsonData('3/movie/popular', page: '$popularPage');
    final popularResponse = PopularResponse.fromJson(response);
      popularMovies = [...popularMovies,...popularResponse.results];
    notifyListeners();
  }

Future<List<Cast>> getMovieCast(int movieId) async {
  if(moviesCast.containsKey(movieId)){
    return moviesCast[movieId]!;
  }
  final jsonData = await _getJsonData('3/movie/$movieId/credits');
  final creditsResponse = CreditResponse.fromJson(jsonData);
  moviesCast[movieId] = creditsResponse.cast;
  return creditsResponse.cast; 
}

  Future<String> _getJsonData(String endpoint, {String page='1'}) async{
    final url = Uri.https(_baseUrl, endpoint,
        {'api_key': _apiKey, 'language': _language, 'page': page});
    final response = await http.get(url);
    return response.body;
  }
  Future<List<Movie>> searchMovie(String query) async{
    final url = Uri.https(_baseUrl, '3/search/movie',
        {'api_key': _apiKey, 'language': _language, 'query': query});
    final response = await http.get(url);
    final searchMovieResponse = SearchMovieResponse.fromJson(response.body);
    return searchMovieResponse.results;
  }
  void getSuggestionsByQuery(String searchTerm){
    debouncer.value = '';
    debouncer.onValue = (value) async{
      final results = await searchMovie(value.toString());
      _suggestionStreamController.add(results);
    };
  final timer = Timer.periodic(const Duration(microseconds: 300), (_) {
    debouncer.value = searchTerm;
  });
  Future.delayed(const Duration(milliseconds: 300)).then((_) => timer.cancel());
  }
}
        