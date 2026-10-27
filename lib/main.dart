import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DepensesApp());

const categories = ['Agricole', 'Magasin', 'Atelier', 'Autre'];
const navy = Color(0xFF192878);
const green = Color(0xFF23863C);

class DepensesApp extends StatelessWidget {
  const DepensesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Mes Dépenses',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: navy,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const Accueil(),
      );
}

class Accueil extends StatefulWidget {
  const Accueil({super.key});

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  List<Map<String, dynamic>> depenses = [];
  String? filtre;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final donnees = jsonDecode(prefs.getString('depenses') ?? '[]') as List;
      if (!mounted) return;
      setState(() {
        depenses = donnees.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lire les dépenses enregistrées')),
      );
    }
  }

  Future<void> sauver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('depenses', jsonEncode(depenses));
  }

  double total(String? categorie) => depenses
      .where((e) => categorie == null || e['categorie'] == categorie)
      .fold<double>(0, (somme, e) => somme + (e['montant'] as num).toDouble());

  String dt(double valeur) {
    final texte = valeur.toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return '$texte DT';
  }

  String dateAff(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> formulaire([int? index]) async {
    final existante = index == null ? null : depenses[index];
    final resultat = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FormulaireDepense(
          initiale: existante == null ? null : Map<String, dynamic>.from(existante),
          categorieInitiale: filtre ?? categories.first,
        ),
      ),
    );
    if (!mounted || resultat == null) return;
    setState(() {
      if (index == null) {
        depenses.insert(0, resultat);
      } else {
        depenses[index] = resultat;
      }
    });
    await sauver();
  }

  Future<void> supprimer(int index) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette dépense ?'),
        content: Text(depenses[index]['libelle'].toString()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (!mounted || confirmation != true) return;
    setState(() => depenses.removeAt(index));
    await sauver();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = depenses.asMap().entries
        .where((e) => filtre == null || e.value['categorie'] == filtre)
        .toList();
    const icones = [Icons.agriculture, Icons.storefront, Icons.build, Icons.more_horiz];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Dépenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: navy,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(children: [
              const Text('TOTAL GÉNÉRAL', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(dt(total(null)), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Secteurs', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  if (filtre != null)
                    TextButton(onPressed: () => setState(() => filtre = null), child: const Text('Voir tout')),
                ]),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.65,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: categories.asMap().entries.map((entry) {
                    final categorie = entry.value;
                    return Card(
                      color: filtre == categorie ? const Color(0xFFE2F0E5) : Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => filtre = filtre == categorie ? null : categorie),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icones[entry.key], color: green),
                              const SizedBox(height: 5),
                              Text(categorie, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(dt(total(categorie)), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text(filtre == null ? 'Toutes les dépenses' : 'Dépenses : $filtre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (visibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('Aucune dépense enregistrée')),
                  ),
                ...visibles.map((entry) => Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Text(entry.value['libelle'].toString()),
                        subtitle: Text('${entry.value['categorie']} • ${dateAff(entry.value['date'].toString())}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(dt((entry.value['montant'] as num).toDouble()),
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          PopupMenuButton<String>(
                            onSelected: (choix) => choix == 'modifier'
                                ? formulaire(entry.key)
                                : supprimer(entry.key),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                              PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                            ],
                          ),
                        ]),
                      ),
                    )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => formulaire(),
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

// Écran indépendant : les contrôleurs sont libérés uniquement lorsque
// cet écran est définitivement retiré de l'arbre des widgets.
class FormulaireDepense extends StatefulWidget {
  final Map<String, dynamic>? initiale;
  final String categorieInitiale;

  const FormulaireDepense({
    super.key,
    required this.initiale,
    required this.categorieInitiale,
  });

  @override
  State<FormulaireDepense> createState() => _FormulaireDepenseState();
}

class _FormulaireDepenseState extends State<FormulaireDepense> {
  final cleFormulaire = GlobalKey<FormState>();
  late final TextEditingController libelle;
  late final TextEditingController montant;
  late String categorie;
  late DateTime date;

  @override
  void initState() {
    super.initState();
    libelle = TextEditingController(text: widget.initiale?['libelle']?.toString() ?? '');
    montant = TextEditingController(text: widget.initiale?['montant']?.toString() ?? '');
    final initialeCategorie = widget.initiale?['categorie']?.toString() ?? widget.categorieInitiale;
    categorie = categories.contains(initialeCategorie) ? initialeCategorie : categories.first;
    date = DateTime.tryParse(widget.initiale?['date']?.toString() ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    libelle.dispose();
    montant.dispose();
    super.dispose();
  }

  Future<void> choisirDate() async {
    final choix = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (choix != null && mounted) setState(() => date = choix);
  }

  void enregistrer() {
    if (!cleFormulaire.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'libelle': libelle.text.trim(),
      'montant': double.parse(montant.text.trim().replaceAll(',', '.')),
      'categorie': categorie,
      'date': date.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initiale == null ? 'Nouvelle dépense' : 'Modifier la dépense',
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: navy,
      ),
      body: SafeArea(
        child: Form(
          key: cleFormulaire,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: libelle,
                decoration: const InputDecoration(labelText: 'Libellé', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.sentences,
                validator: (valeur) => valeur == null || valeur.trim().isEmpty
                    ? 'Saisir un libellé' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: montant,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montant (DT)', border: OutlineInputBorder()),
                validator: (valeur) {
                  final nombre = double.tryParse((valeur ?? '').trim().replaceAll(',', '.'));
                  return nombre == null || !nombre.isFinite || nombre <= 0
                      ? 'Saisir un montant positif' : null;
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: categorie,
                decoration: const InputDecoration(labelText: 'Secteur', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (valeur) {
                  if (valeur != null) setState(() => categorie = valeur);
                },
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: choisirDate,
                icon: const Icon(Icons.calendar_month),
                label: Text('Date : ${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/${date.year}'),
              ),
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: enregistrer,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer la dépense'),
                style: FilledButton.styleFrom(
                  backgroundColor: navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
