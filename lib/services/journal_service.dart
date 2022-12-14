import 'dart:convert';
import 'dart:io';
import 'package:flutter_webapi_first_course/models/journal.dart';
import 'package:flutter_webapi_first_course/services/webclient.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class JournalService {
  String url = WebClient.url;
  http.Client client = WebClient().client;
  static const String resource = "journals/";

  String getURL() {
    return "$url$resource";
  }

  Uri getUri() {
    return Uri.parse(getURL());
  }

  Future<bool> register(Journal journal) async {
    String token = await getToken();
    String jsonJournal = json.encode(journal.toMap());

    http.Response response = await client.post(
      getUri(),
      headers: {
        'Content-type': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonJournal,
    );

    if (response.statusCode != 201) {
      if (json.decode(response.body) == "jwt expired") {
        throw TokenNotValidException();
      }

      throw HttpException(response.body);
    }

    return true;
  }

  Future<bool> edit(String id, Journal journal) async {
    journal.updatedAt = DateTime.now();
    String token = await getToken();
    String jsonJournal = json.encode(journal.toMap());

    http.Response response = await client.put(
      Uri.parse("${getURL()}$id"),
      headers: {
        'Content-type': 'application/json',
        "Authorization": "Bearer $token",
      },
      body: jsonJournal,
    );

    if (response.statusCode != 200) {
      if (json.decode(response.body) == "jwt expired") {
        throw TokenNotValidException();
      }

      throw HttpException(response.body);
    }

    return true;
  }

  Future<List<Journal>> getAll({required String id}) async {
    String token = await getToken();
    http.Response response = await client.get(
        Uri.parse("${url}users/$id/journals"),
        headers: {"Authorization": "Bearer $token"});

    if (response.statusCode != 200) {
      if (json.decode(response.body) == "jwt expired") {
        throw TokenNotValidException();
      }

      throw HttpException(response.body);
    }

    List<Journal> list = [];

    List<dynamic> listDynamic = json.decode(response.body);

    for (var jsonMap in listDynamic) {
      list.add(Journal.fromMap(jsonMap));
    }

    return list;
  }

  Future<bool> delete(String id) async {
    String token = await getToken();
    http.Response response = await http.delete(
      Uri.parse("${getURL()}$id"),
      headers: {
        'Content-type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      if (json.decode(response.body) == "jwt expired") {
        throw TokenNotValidException();
      }

      throw HttpException(response.body);
    }

    return true;
  }

  Future<String> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    if (token != null) {
      return token;
    }
    return '';
  }
}

class TokenNotValidException implements Exception {}
