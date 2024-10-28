!> @brief Illustrates how to use MPI_Mprobe and MPI_Mrecv.
!> @details This application demonstrates receiving a message using MPI_Mprobe
!> to get a message handle, then using MPI_Mrecv to receive the message.
!> Unlike MPI_Probe, MPI_Mprobe provides a message handle that guarantees 
!> receiving the specific probed message, regardless of any intervening probe 
!> or receive operations. This allows the application to:
!> 1. Query message properties without receiving it
!> 2. Allocate exact buffer size based on probed message length
!> 3. Ensure the exact probed message is received, even if other messages arrive
!>
!> This application is meant to be run with 2 processes: a sender and a receiver.
PROGRAM main
    USE mpi

    IMPLICIT NONE

    INTEGER :: ierror
    INTEGER :: size
    INTEGER, PARAMETER :: sender_rank = 0
    INTEGER, PARAMETER :: receiver_rank = 1
    INTEGER :: my_rank
    INTEGER, ALLOCATABLE :: buffer(:)
    INTEGER :: count
    INTEGER :: status(MPI_STATUS_SIZE)
    INTEGER :: message
    INTEGER :: i

    CALL MPI_Init(ierror)

    ! Size of the default communicator
    CALL MPI_Comm_size(MPI_COMM_WORLD, size, ierror)
    IF (size .NE. 2) THEN
        WRITE(*,'(A)') 'This application is meant to be run with 2 processes.'
        CALL MPI_Abort(MPI_COMM_WORLD, -1, ierror)
    END IF

    ! Get my rank and do the corresponding job
    CALL MPI_Comm_rank(MPI_COMM_WORLD, my_rank, ierror)
    SELECT CASE (my_rank)
        CASE (sender_rank)
            count = 3
            ALLOCATE(buffer(0:count-1))
            buffer = (/123, 456, 789/)
            WRITE(*,'(A,I0,A,I0,A,I0,A,I0,A)') 'Process ', my_rank, &
                ': sending a message containing 3 ints (', &
                buffer(0), ', ', buffer(1), ', ', buffer(2), ')'
            CALL MPI_Send(buffer, 3, MPI_INTEGER, receiver_rank, 0, &
                         MPI_COMM_WORLD, ierror)
        CASE (receiver_rank)
            ! Probe for message and get message handle
            CALL MPI_Mprobe(sender_rank, 0, MPI_COMM_WORLD, message, &
                           status, ierror)
            WRITE(*,'(A,I0,A)') 'Process ', my_rank, &
                ': probed message and got message handle.'

            ! Get count of incoming integers
            CALL MPI_Get_count(status, MPI_INTEGER, count, ierror)

            ! Allocate buffer and receive using message handle
            ALLOCATE(buffer(0:count-1))
            CALL MPI_Mrecv(buffer, count, MPI_INTEGER, message, status, ierror)

            WRITE(*,'(A,I0,A,I0,A)',advance='no') 'Process ', my_rank, &
                ': received message with ', count, ' ints:'
            DO i = 0, count-1
                WRITE(*,'(A,I0)',advance='no') ' ', buffer(i)
            END DO
            WRITE(*,'(A)') ''
    END SELECT

    IF(ALLOCATED(buffer)) DEALLOCATE(buffer)
    CALL MPI_Finalize(ierror)
END PROGRAM main
