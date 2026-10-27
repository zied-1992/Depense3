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
    title: 'Mes Dépenses', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: navy, scaffoldBackgroundColor: const Color(0xFFF5F7FA)),
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
  void initState() { super.initState(); charger(); }
  Future<void> charger() async {
    final p = await SharedPreferences.getInstance();
    try {
      final decoded = jsonDecode(p.getString('depenses') ?? '[]') as List;
      if (mounted) setState(() => depenses = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lire les dépenses enregistrées'))); }
  }
  Future<void> sauver() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('depenses', jsonEncode(depenses));
  }
  double total(String? cat) => depenses.where((e) => cat == null || e['categorie'] == cat).fold<double>(0, (sum, e) => sum + ((e['montant'] as num).toDouble()));
  String dt(double n) => '${n.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} DT';
  String dateAff(String iso) { final d = DateTime.tryParse(iso); return d == null ? iso : '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}'; }
  Future<void> formulaire([int? index]) async {
    final existante = index == null ? null : depenses[index];
    final libelle = TextEditingController(text: existante?['libelle']?.toString() ?? '');
    final montant = TextEditingController(text: existante?['montant']?.toString() ?? '');
    String cat = existante?['categorie']?.toString() ?? filtre ?? categories.first;
    DateTime date = DateTime.tryParse(existante?['date']?.toString() ?? '') ?? DateTime.now();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String,dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
      title: Text(index == null ? 'Nouvelle dépense' : 'Modifier la dépense'),
      content: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: libelle, decoration: const InputDecoration(labelText: 'Libellé'), validator: (v) => v == null || v.trim().isEmpty ? 'Saisir un libellé' : null),
        TextFormField(controller: montant, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Montant (DT)'), validator: (v) { final n = double.tryParse((v ?? '').replaceAll(',', '.')); return n == null || n <= 0 ? 'Saisir un montant positif' : null; }),
        DropdownButtonFormField<String>(value: cat, decoration: const InputDecoration(labelText: 'Secteur'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) update(() => cat = v); }),
        const SizedBox(height: 12),
        OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(dateAff(date.toIso8601String())), onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) update(() => date = d); }),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, {'libelle': libelle.text.trim(), 'montant': double.parse(montant.text.replaceAll(',', '.')), 'categorie': cat, 'date': date.toIso8601String()}); }, child: const Text('Enregistrer'))],
    )));
    libelle.dispose(); montant.dispose();
    if (result != null) { setState(() { if (index == null) { depenses.insert(0, result); } else { depenses[index] = result; } }); await sauver(); }
  }
  Future<void> supprimer(int index) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Supprimer cette dépense ?'), content: Text(depenses[index]['libelle'].toString()), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer'))]));
    if (ok == true) { setState(() => depenses.removeAt(index)); await sauver(); }
  }
  @override
  Widget build(BuildContext context) {
    final visible = depenses.asMap().entries.where((e) => filtre == null || e.value['categorie'] == filtre).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Dépenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: navy),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: navy, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))), child: Column(children: [const Text('TOTAL GÉNÉRAL', style: TextStyle(color: Colors.white70)), const SizedBox(height: 8), Text(dt(total(null)), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))])),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Secteurs', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), if (filtre != null) TextButton(onPressed: () => setState(() => filtre = null), child: const Text('Voir tout'))]),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.65, mainAxisSpacing: 10, crossAxisSpacing: 10, children: categories.asMap().entries.map((entry) {
            final icons = [Icons.agriculture, Icons.storefront, Icons.build, Icons.more_horiz];
            final cat = entry.value;
            return Card(color: filtre == cat ? const Color(0xFFE2F0E5) : Colors.white, child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => setState(() => filtre = filtre == cat ? null : cat), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icons[entry.key], color: green), const SizedBox(height: 5), Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)), Text(dt(total(cat)), style: const TextStyle(fontWeight: FontWeight.bold))]))));
          }).toList()),
          const SizedBox(height: 18), Text(filtre == null ? 'Toutes les dépenses' : 'Dépenses : $filtre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (visible.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Center(child: Text('Aucune dépense enregistrée'))),
          ...visible.map((entry) => Card(color: Colors.white, child: ListTile(title: Text(entry.value['libelle'].toString()), subtitle: Text('${entry.value['categorie']} • ${dateAff(entry.value['date'].toString())}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(dt((entry.value['montant'] as num).toDouble()), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), PopupMenuButton<String>(onSelected: (v) => v == 'modifier' ? formulaire(entry.key) : supprimer(entry.key), itemBuilder: (_) => [const PopupMenuItem(value: 'modifier', child: Text('Modifier')), const PopupMenuItem(value: 'supprimer', child: Text('Supprimer'))])])))),
          const SizedBox(height: 80),
        ])),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => formulaire(), backgroundColor: green, foregroundColor: Colors.white, icon: const Icon(Icons.add), label: const Text('Ajouter')),
    );
  }
}
