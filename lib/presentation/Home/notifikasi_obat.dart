import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manajemen_obat/core/core.dart';
import 'package:manajemen_obat/core/components/spaces.dart';
import 'package:manajemen_obat/data/models/request/notification/add_notification_schedule_request_model.dart';
import 'package:manajemen_obat/data/models/request/notification/update_notification_schedule_request_model.dart';
import 'package:manajemen_obat/data/models/response/notification_schedule_response_model.dart'; // Import Model Response
import 'package:manajemen_obat/presentation/notification/bloc/notification_bloc.dart'; // Import BLoC

class NotifikasiObat extends StatefulWidget {
  final int medicationGlobalId;
  final int patientGlobalId;
  final String medicationName;
  final String patientName;

  const NotifikasiObat({
    Key? key,
    required this.medicationGlobalId,
    required this.patientGlobalId,
    required this.medicationName,
    required this.patientName,
  }) : super(key: key);

  @override
  State<NotifikasiObat> createState() => _NotifikasiObatState();
}

class _NotifikasiObatState extends State<NotifikasiObat> {
  final GlobalKey<FormState> _addEditFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Panggil event untuk memuat jadwal notifikasi saat halaman diinisialisasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationSchedules();
    });
  }

  void _loadNotificationSchedules() {
    context.read<NotificationBloc>().add(
      LoadNotificationSchedulesForMedicationAndPatient(
        medicationGlobalId: widget.medicationGlobalId,
        patientGlobalId: widget.patientGlobalId,
      ),
    );
  }

  // Helper method for consistent InputDecoration styling
  InputDecoration _inputDecoration(
    String labelText, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.grey),
      floatingLabelStyle: const TextStyle(
        color: AppColors.deepPurple,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.light),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.light),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.deepPurple, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.red, width: 2.0),
      ),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    );
  }

  Future<void> _showAddEditScheduleDialog(
    BuildContext context, {
    NotificationScheduleData? schedule,
  }) async {
    final TextEditingController timeController = TextEditingController(
      text: schedule?.scheduleTime ?? '',
    );
    DateTime? selectedStartDate = schedule?.startDate;
    DateTime? selectedEndDate = schedule?.endDate;
    bool isActive = schedule?.isActive ?? true;

    if (schedule != null) {
      timeController.text = schedule.scheduleTime;
      selectedStartDate = schedule.startDate;
      selectedEndDate = schedule.endDate;
      isActive = schedule.isActive;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> _pickTime() async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: AppColors.deepPurple,
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.deepPurple,
                      ),
                      buttonTheme: const ButtonThemeData(
                        textTheme: ButtonTextTheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  timeController.text =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            }

            Future<void> _pickDate(bool isStartDate) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate:
                    isStartDate
                        ? (selectedStartDate ?? DateTime.now())
                        : (selectedEndDate ?? DateTime.now()),
                firstDate: DateTime.now().subtract(
                  const Duration(days: 365 * 5),
                ), // 5 tahun lalu
                lastDate: DateTime.now().add(
                  const Duration(days: 365 * 5),
                ), // 5 tahun ke depan
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      primaryColor: AppColors.deepPurple,
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.deepPurple,
                      ),
                      buttonTheme: const ButtonThemeData(
                        textTheme: ButtonTextTheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStartDate) {
                    selectedStartDate = picked;
                    if (selectedEndDate != null &&
                        selectedStartDate!.isAfter(selectedEndDate!)) {
                      selectedEndDate =
                          selectedStartDate; // Adjust end date if it's before start date
                    }
                  } else {
                    selectedEndDate = picked;
                    if (selectedStartDate != null &&
                        selectedEndDate!.isBefore(selectedStartDate!)) {
                      selectedStartDate =
                          selectedEndDate; // Adjust start date if it's after end date
                    }
                  }
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10.0,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              title: Text(
                schedule == null
                    ? 'Tambah Jadwal Pengingat'
                    : 'Edit Jadwal Pengingat',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  fontSize: 22,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _addEditFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Obat: ${widget.medicationName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SpaceHeight(8),
                      Text(
                        'Pasien: ${widget.patientName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SpaceHeight(16),
                      TextFormField(
                        controller: timeController,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: _inputDecoration(
                          'Waktu Pengingat (HH:MM)',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.access_time,
                              color: AppColors.deepPurple,
                            ),
                            onPressed: _pickTime,
                          ),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Waktu pengingat wajib diisi'
                                    : null,
                      ),
                      const SpaceHeight(16),
                      TextFormField(
                        readOnly: true,
                        onTap: () => _pickDate(true),
                        controller: TextEditingController(
                          text:
                              selectedStartDate == null
                                  ? ''
                                  : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(selectedStartDate!),
                        ),
                        decoration: _inputDecoration(
                          'Tanggal Mulai (YYYY-MM-DD)',
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today,
                              color: AppColors.deepPurple,
                            ),
                            onPressed: () => _pickDate(true),
                          ),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Tanggal mulai wajib diisi'
                                    : null,
                      ),
                      const SpaceHeight(16),
                      TextFormField(
                        readOnly: true,
                        onTap: () => _pickDate(false),
                        controller: TextEditingController(
                          text:
                              selectedEndDate == null
                                  ? ''
                                  : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(selectedEndDate!),
                        ),
                        decoration: _inputDecoration(
                          'Tanggal Berakhir (YYYY-MM-DD) (Opsional)',
                          suffixIcon:
                              selectedEndDate != null
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.grey,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedEndDate = null;
                                      });
                                    },
                                  )
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      color: AppColors.deepPurple,
                                    ),
                                    onPressed: () => _pickDate(false),
                                  ),
                        ),
                      ),
                      const SpaceHeight(16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Aktifkan Pengingat',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.black,
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (bool value) {
                              setDialogState(() {
                                isActive = value;
                              });
                            },
                            activeColor: AppColors.deepPurple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.grey,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_addEditFormKey.currentState!.validate()) {
                      if (selectedStartDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tanggal mulai wajib diisi.'),
                          ),
                        );
                        return;
                      }

                      if (schedule == null) {
                        // Tambah jadwal baru
                        context.read<NotificationBloc>().add(
                          AddNotificationSchedule(
                            request: AddNotificationScheduleRequestModel(
                              medicationId: widget.medicationGlobalId,
                              patientGlobalId: widget.patientGlobalId,
                              scheduleTime: timeController.text,
                              startDate: DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedStartDate!),
                              endDate:
                                  selectedEndDate == null
                                      ? null
                                      : DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(selectedEndDate!),
                              isActive: isActive,
                              recipientFamilyIds:
                                  [], // Ini akan diisi di backend
                            ),
                          ),
                        );
                      } else {
                        // Edit jadwal yang sudah ada
                        context.read<NotificationBloc>().add(
                          UpdateNotificationSchedule(
                            scheduleId: schedule.id,
                            request: UpdateNotificationScheduleRequestModel(
                              scheduleTime: timeController.text,
                              startDate: DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedStartDate!),
                              endDate:
                                  selectedEndDate == null
                                      ? null
                                      : DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(selectedEndDate!),
                              isActive: isActive,
                              // medicationId dan patientGlobalId tidak perlu di-update di sini
                              // karena itu adalah jadwal untuk obat & pasien yang sudah ada
                            ),
                          ),
                        );
                      }
                      Navigator.pop(dialogContext); // Tutup dialog
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepPurple,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(schedule == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteSchedule(
    BuildContext context,
    int scheduleId,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            title: const Text(
              'Konfirmasi Hapus Pengingat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                fontSize: 22,
              ),
            ),
            content: const Text(
              'Apakah Anda yakin ingin menghapus jadwal pengingat ini?',
              style: TextStyle(color: AppColors.grey, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grey,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      context.read<NotificationBloc>().add(
        DeleteNotificationSchedule(
          scheduleId: scheduleId,
          medicationGlobalId: widget.medicationGlobalId, // Teruskan ID ini
          patientGlobalId: widget.patientGlobalId, // Teruskan ID ini
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSheet,
      appBar: AppBar(
        title: Text(
          'Pengingat In-App: ${widget.medicationName}',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            // Setelah aksi berhasil dan data dimuat ulang, state akan berubah ke NotificationLoaded
          } else if (state is NotificationError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.deepPurple),
              ),
            );
          } else if (state is NotificationLoaded) {
            if (state.schedules.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Belum ada jadwal pengingat untuk obat ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.schedules.length,
              itemBuilder: (context, index) {
                final schedule = state.schedules[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  shadowColor: AppColors.deepPurple.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.deepPurple,
                            ),
                            const SpaceWidth(8),
                            Text(
                              'Waktu: ${schedule.scheduleTime}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            const Spacer(),
                            // Tombol Edit
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.deepPurple,
                              ),
                              onPressed:
                                  () => _showAddEditScheduleDialog(
                                    context,
                                    schedule: schedule,
                                  ),
                              tooltip: 'Edit Jadwal Pengingat',
                            ),
                            // Tombol Hapus
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.redCustom,
                              ),
                              onPressed:
                                  () => _confirmDeleteSchedule(
                                    context,
                                    schedule.id,
                                  ),
                              tooltip: 'Hapus Jadwal Pengingat',
                            ),
                          ],
                        ),
                        const SpaceHeight(8),
                        Text(
                          'Periode: ${DateFormat('dd MMM yyyy').format(schedule.startDate)} - '
                          '${schedule.endDate == null ? 'Selamanya' : DateFormat('dd MMM yyyy').format(schedule.endDate!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                        const SpaceHeight(4),
                        Row(
                          children: [
                            Text(
                              'Status: ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.grey,
                              ),
                            ),
                            Text(
                              schedule.isActive ? 'Aktif' : 'Tidak Aktif',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    schedule.isActive
                                        ? AppColors.green
                                        : AppColors.redCustom,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat jadwal pengingat: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadNotificationSchedules,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepPurple,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditScheduleDialog(context),
        backgroundColor: AppColors.deepPurple,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
