import 'package:camera_app/new_to_keep/video_filter.dart';
import 'package:flutter/material.dart';

class FilterSelector extends StatelessWidget {
  final List<VideoFilter> filters;
  final VideoFilter selectedFilter;
  final Function(VideoFilter) onFilterSelected;

  const FilterSelector({
    Key? key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: filter == selectedFilter
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter,
                    color: Colors.white,
                  ),
                  SizedBox(height: 4),
                  Text(
                    filter.name,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
