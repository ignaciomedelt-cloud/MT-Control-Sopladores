
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const MTApp());

class MTApp extends StatelessWidget {
  const MTApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control Sopladores',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ControlPage(),
    );
  }
}

class SopladorRow {
  bool fs = false;
  final List<String> m = List.filled(5, '');
  String hz = '';
  String obs = '';
}

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final List<SopladorRow> data = List.generate(25, (_) => SopladorRow());
  String color = 'green';
  int? selected;
  final fechaCtl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final horaCtl = TextEditingController(text: DateFormat('HH:mm').format(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control Sopladores')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _field('Fecha', _dateField(context)),
              _field('Hora', _timeField(context)),
              _toggle('Abierto', color=='green', const Color(0xFF20C997), () => setState(()=>color='green')),
              _toggle('Cerrado', color=='red', const Color(0xFFFF4D4F), () => setState(()=>color='red')),
              ElevatedButton(onPressed: selected==null?null:() {
                final idx = selected!;
                setState((){
                  data[idx].fs = !data[idx].fs;
                  if(data[idx].fs){ for(var i=0;i<5;i++){ data[idx].m[i]=''; } }
                });
              }, child: const Text('F/S')),
              ElevatedButton(onPressed: _exportPdf, child: const Text('📄 Exportar PDF')),
            ]),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1000),
                child: _table(context),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _table(BuildContext context){
    final headerStyle = const TextStyle(color: Color(0xFFAEB8C7), fontSize: 12);
    final border = const BorderSide(color: Color(0xFF222733));
    final rows = <TableRow>[];
    rows.add(TableRow(children: [
      _th('Soplador', headerStyle), _th('Manifold 01', headerStyle),
      _th('Manifold 02', headerStyle), _th('Manifold 03', headerStyle),
      _th('Manifold 04', headerStyle), _th('Manifold 05', headerStyle),
      _th('HZ', headerStyle), _th('Obs.', headerStyle),
    ]));
    for(int i=0;i<25;i++){
      final r=data[i]; final sel = selected==i;
      rows.add(TableRow(children: [
        _td(Container(
          color: const Color(0xFF12151D),
          child: InkWell(
            onTap: ()=>setState(()=>selected=sel?null:i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children:[
                Text('Soplador ${_pad(i+1)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD3DAE5))),
                if(r.fs) const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('F/S', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFFCC00))),
                ),
              ]),
            ),
          ),
        ), border),
        if(r.fs)
          _td(Center(child: const Text('FUERA DE SERVICIO', style: TextStyle(fontWeight: FontWeight.bold))), border, colspan: 5)
        else ...List.generate(5, (m){
          Color bg = const Color(0xFF0F131B);
          if(r.m[m]=='green') bg = const Color(0xFF20C997);
          if(r.m[m]=='red') bg = const Color(0xFFFF4D4F);
          return _td(GestureDetector(
            onTap: ()=>setState(()=> r.m[m] = (r.m[m]==color)?'':color ),
            child: Container(height: 40, color: bg),
          ), border);
        }),
        _td(Padding(
          padding: const EdgeInsets.symmetric(horizontal:8),
          child: TextField(
            onChanged: (v)=>r.hz=v,
            controller: TextEditingController(text: r.hz),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            keyboardType: TextInputType.number,
          ),
        ), border),
        _td(Padding(
          padding: const EdgeInsets.all(6),
          child: TextField(
            onChanged: (v)=>r.obs=v,
            controller: TextEditingController(text: r.obs),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            maxLines: 3,
          ),
        ), border),
      ]));
    }
    return Table(
      border: TableBorder.symmetric(inside: const BorderSide(color: Color(0xFF222733))),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(90),2: FixedColumnWidth(90),3: FixedColumnWidth(90),
        4: FixedColumnWidth(90),5: FixedColumnWidth(90),6: FixedColumnWidth(90),
        7: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _field(String label, Widget input)=>Container(
    padding: const EdgeInsets.symmetric(horizontal:8,vertical:6),
    decoration: BoxDecoration(color: const Color(0xFF12151D), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF232A39))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize:12,color: Color(0xFFA9B4C7))), const SizedBox(width:6), input]),
  );

  Widget _dateField(BuildContext context)=>SizedBox(
    width:140,
    child: TextField(readOnly:true, controller: fechaCtl, onTap: () async{
      final now=DateTime.now();
      final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(2020), lastDate: DateTime(2100));
      if(picked!=null){ fechaCtl.text = DateFormat('yyyy-MM-dd').format(picked); }
    }, decoration: const InputDecoration(border: InputBorder.none)),
  );

  Widget _timeField(BuildContext context)=>SizedBox(
    width:100,
    child: TextField(readOnly:true, controller: horaCtl, onTap: () async{
      final now = TimeOfDay.now();
      final picked = await showTimePicker(context: context, initialTime: now);
      if(picked!=null){ final dt = DateFormat.jm().parse(picked.format(context)); horaCtl.text = DateFormat('HH:mm').format(dt); }
    }, decoration: const InputDecoration(border: InputBorder.none)),
  );

  Widget _toggle(String label, bool active, Color dot, VoidCallback onTap)=>InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal:12,vertical:8),
      decoration: BoxDecoration(color: const Color(0xFF131722), borderRadius: BorderRadius.circular(10), border: Border.all(color: active? const Color(0xFF3B82F6): const Color(0xFF2A3142))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width:12,height:12,decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width:6), Text(label, style: const TextStyle(fontWeight: FontWeight.w600))]),
    ),
  );

  TableCell _th(String txt, TextStyle style)=>TableCell(child: Container(padding: const EdgeInsets.all(8), color: const Color(0xFF12161F), child: Text(txt, style: style)));
  TableCell _td(Widget child, BorderSide border, {int colspan=1})=>TableCell(child: Container(
    decoration: BoxDecoration(border: Border(left: border, right: border, bottom: border)),
    child: child,
  ));

  String _pad(int v)=>v.toString().padLeft(2,'0');

  Future<void> _exportPdf() async{
    final doc = pw.Document();
    final fecha = fechaCtl.text;
    final hora  = horaCtl.text;
    final headerStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final cellStyle   = pw.TextStyle(fontSize: 9);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx){
        return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Row(children: [pw.PdfLogo(), pw.SizedBox(width:6), pw.Text('MT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))]),
            pw.Text('Fecha: $fecha • Hora: $hora', style: const pw.TextStyle(fontSize: 10))
          ]),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#e5e7eb'), width: 0.5),
            columnWidths: {0: const pw.FixedColumnWidth(78), 1: const pw.FixedColumnWidth(70), 2: const pw.FixedColumnWidth(70), 3: const pw.FixedColumnWidth(70), 4: const pw.FixedColumnWidth(70), 5: const pw.FixedColumnWidth(70), 6: const pw.FixedColumnWidth(70), 7: const pw.FlexColumnWidth()},
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: ['Soplador','Manifold 01','Manifold 02','Manifold 03','Manifold 04','Manifold 05','HZ','Obs.']
                  .map((t)=> pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t, style: headerStyle))).toList(),
              ),
              ...List.generate(25, (i){
                final r = data[i];
                final manifoldCells = r.fs
                    ? [pw.TableCell(verticalAlignment: pw.TableCellVerticalAlignment.middle, child: pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Center(child: pw.Text('FUERA DE SERVICIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))))]
                    : List.generate(5, (m){
                        final col = r.m[m]=='green'? PdfColor.fromHex('#20c997') : r.m[m]=='red'? PdfColor.fromHex('#ff4d4f') : PdfColor.fromHex('#ffffff');
                        return pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Container(height: 10, decoration: pw.BoxDecoration(color: col, border: pw.Border.all(color: PdfColor.fromHex('#e5e7eb'), width: 0.5), borderRadius: pw.BorderRadius.circular(2))));
                      });
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Soplador ${i+1}'.padLeft(11), style: cellStyle)),
                  if(r.fs) ...[pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Center(child: pw.Text('FUERA DE SERVICIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))))] else ...manifoldCells,
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(r.hz, style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(r.obs, style: cellStyle)),
                ]);
              }),
            ],
          ),
        ]);
      }
    ));

    await Printing.layoutPdf(onLayout: (format) async => await doc.save());
  }
}
