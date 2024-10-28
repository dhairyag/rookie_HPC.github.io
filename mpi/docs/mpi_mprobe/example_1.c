#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

/**
 * @brief Illustrates how to use MPI_Mprobe and MPI_Mrecv.
 * @details This application demonstrates receiving a message using MPI_Mprobe 
 * to get a message handle, then using MPI_Mrecv to receive the message.
 * Unlike MPI_Probe, MPI_Mprobe provides a message handle that guarantees 
 * receiving the specific probed message, regardless of any intervening probe 
 * or receive operations. This allows the application to:
 * 1. Query message properties without receiving it
 * 2. Allocate exact buffer size based on probed message length
 * 3. Ensure the exact probed message is received, even if other messages arrive
 * 
 * This application is meant to be run with 2 processes: a sender and a receiver.
 **/
int main(int argc, char* argv[])
{
    MPI_Init(&argc, &argv);

    // Size of the default communicator
    int size;
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    if(size != 2)
    {
        printf("This application is meant to be run with 2 processes.\n");
        MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
    }

    // Get my rank and do the corresponding job
    enum role_ranks { SENDER, RECEIVER };
    int my_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
    switch(my_rank)
    {
        case SENDER:
        {
            int buffer[3] = {123, 456, 789};
            printf("Process %d: sending a message containing 3 ints (%d, %d, %d).\n", 
                   my_rank, buffer[0], buffer[1], buffer[2]);
            MPI_Send(buffer, 3, MPI_INT, RECEIVER, 0, MPI_COMM_WORLD);
            break;
        }
        case RECEIVER:
        {
            // Variables for message probe
            MPI_Message message;
            MPI_Status status;
            
            // Probe for incoming message and get message handle
            MPI_Mprobe(SENDER, 0, MPI_COMM_WORLD, &message, &status);
            printf("Process %d: probed message and got message handle.\n", my_rank);

            // Get count of incoming integers
            int count;
            MPI_Get_count(&status, MPI_INT, &count);

            // Allocate buffer and receive the message using the handle
            int* buffer = (int*)malloc(sizeof(int) * count);
            MPI_Mrecv(buffer, count, MPI_INT, &message, &status);

            printf("Process %d: received message with %d ints:", my_rank, count);
            for(int i = 0; i < count; i++)
            {
                printf(" %d", buffer[i]);
            }
            printf(".\n");

            free(buffer);
            break;
        }
    }

    MPI_Finalize();
    return EXIT_SUCCESS;
}
