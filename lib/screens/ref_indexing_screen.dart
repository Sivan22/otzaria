import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_bloc.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_event.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_repository.dart';
import 'package:otzaria/bloc/ref_indexing/ref_indexing_state.dart';
import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/bloc/library/library_bloc.dart';

class RefIndexingScreen extends StatelessWidget {
  const RefIndexingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RefIndexingBloc(
        refIndexingRepository: RefIndexingRepository(
          dataProvider: IsarDataProvider.instance,
        ),
        libraryBloc: BlocProvider.of<LibraryBloc>(
            context), // Assuming LibraryBloc is available
      ),
      child: _RefIndexingScreenView(),
    );
  }
}

class _RefIndexingScreenView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<RefIndexingBloc, RefIndexingState>(
      // Add BlocListener
      listener: (context, state) {
        if (state is RefIndexingComplete) {
          print('Ref indexing complete!'); // Print message on complete
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('אינדקס מקורות')),
        ),
        body: Center(
          child: Column(
            children: [
              _buildIndexingButton(context),
              _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndexingButton(BuildContext context) {
    return BlocBuilder<RefIndexingBloc, RefIndexingState>(
      // Wrap with BlocBuilder
      builder: (context, state) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: ElevatedButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: const Text(
                      'האם ברצונך ליצור אינדקס מקורות? הדבר יאפס את האינדקס הקיים ועלול לקחת זמן ארוך מאד.',
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('ביטול'),
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                      ElevatedButton(
                        child: const Text('אישור'),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ],
                  ),
                );
                if (result == true) {
                  BlocProvider.of<RefIndexingBloc>(context)
                      .add(StartRefIndexing()); // Dispatch event
                }
              },
              child: const Text(
                'יצירת אינדקס מקורות',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return BlocBuilder<RefIndexingBloc, RefIndexingState>(
      builder: (context, state) {
        if (state is RefIndexingInProgress) {
          // Show progress only in InProgress state
          return ValueListenableBuilder(
            valueListenable: IsarDataProvider.instance.refsNumOfbooksDone,
            builder: (context, valueDone, child) {
              if (valueDone == null) {
                return const SizedBox.shrink();
              }
              return ValueListenableBuilder(
                valueListenable: IsarDataProvider.instance.refsNumOfbooksTotal,
                builder: (context, valueTotal, child) {
                  if (valueTotal == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 50),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(20),
                          value: valueDone / valueTotal,
                        ),
                        Text(' $valueTotal / $valueDone'),
                      ],
                    ),
                  );
                },
              );
            },
          );
        } else {
          return const SizedBox.shrink(); // Hide progress in other states
        }
      },
    );
  }
}
