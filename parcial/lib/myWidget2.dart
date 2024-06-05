import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'jwt.dart';
import 'database.dart';
import 'app_state.dart';
import 'main.dart';

class ArticuloGridView extends StatefulWidget {
  const ArticuloGridView({Key? key}) : super(key: key);

  @override
  _ArticuloGridViewState createState() => _ArticuloGridViewState();
}

class _ArticuloGridViewState extends State<ArticuloGridView> {
  late Future<List<Articulo>> _articulosFuture;
  late Map<int, bool> _starredMap;
  bool _isGridView =
      false; // flag para determinar si se muestra gridview o listview

  @override
  void initState() {
    super.initState();
    _articulosFuture = Articulo.getArticulos();
    //mapa de cuáles artículos ya han sido elegidos como favoritos para rellenar su estrella
    _starredMap = {};
  }

  Future<void> _loadData(AsyncSnapshot<List<Articulo>> snapshot) async {
    final userDatabase =
        Provider.of<AppState>(context, listen: false).userDatabase;
    final idOfUser = await JWTGenerator().authenticateToken();
    final favoritos =
        await userDatabase.getArticulosFavoritos(int.parse(idOfUser));
    //mapa de cuáles artículos ya han sido elegidos como favoritos para rellenar su estrella
    final starredMap = <int, bool>{};
    // Update the _starredMap based on the favoritos list
    favoritos.forEach((favorito) {
      final index = snapshot.data!
          .indexWhere((articulo) => articulo.id == favorito.articuloId);
      if (index >= 0) {
        starredMap[index] = true;
      }
    });
    setState(() {
      _starredMap = starredMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDatabase =
        Provider.of<AppState>(context, listen: false).userDatabase;

    return Expanded(
      child: FutureBuilder<List<Articulo>>(
        future: _articulosFuture,
        builder:
            (BuildContext context, AsyncSnapshot<List<Articulo>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              _loadData(snapshot);
              return GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                children: List.generate(snapshot.data!.length, (index) {
                  bool isStarred = _starredMap[index] ?? false;
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.network(
                            snapshot.data![index].image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        ListTile(
                          title: Text(snapshot.data![index].name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(snapshot.data![index].seller),
                              Text(snapshot.data![index].rating.toString()),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isStarred ? Icons.star : Icons.star_border,
                              color: Colors.yellow,
                            ),
                            onPressed: () async {
                              String idOfUser = '';
                              try {
                                idOfUser =
                                    await JWTGenerator().authenticateToken();
                              } catch (e) {
                                if (e is JWTExpiredError) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const MyLoginPage(
                                                  title: 'Login Page')));
                                  return;
                                } else {
                                  print('Error: $e');
                                  return;
                                }
                              }
                              setState(() {
                                _starredMap[index] = !isStarred;
                              });
                              await _loadData(snapshot);
                              if (!isStarred) {
                                // Añadir a la tabla Articulos_favoritos
                                await userDatabase.addArticuloToFavoritos(
                                    snapshot.data![index].id,
                                    int.parse(idOfUser));
                                print("Añadido");
                              } else {
                                // Quitar de la tabla Articulos_favoritos
                                await userDatabase.removeArticuloFromFavoritos(
                                    snapshot.data![index].id,
                                    int.parse(idOfUser));
                                print("Quitado");
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            }
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
