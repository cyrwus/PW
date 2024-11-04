#ifndef AC_SHELL_DLGS_H
#define AC_SHELL_DLGS_H

#include <string>

using namespace std;


#define DLG_OK       1
#define DLG_CANCEL   0
#define DLG_ERROR   -1


void msgHello();
void msgUnknownOperation();
void msgEmptyProject();
void msgSourceInfo();
void msgFileNotFound();
void msgDataLoaded(string filename);
void msgDataIncorrect(string filename);
void msgDataIncomplete(string filename);
void msgNodeNotFound();
void msgUnknownError();

void mnuOptionsDSP();

void wndHelp();
void wndGraph(string properties[]);
void wndNodes(string *nodes[], int n);
void wndEdges(string *edges[], int n);
void wndPaths(int startId, string *itinerary[], int n);

int dlgNodeId(string ask, int lBound, int uBound, int &Id);
int dlgOverride();
int dlgRetry();
int dlgQuit();
int dlgOptionsDSP();

#endif // AC_SHELL_DLGS_H
