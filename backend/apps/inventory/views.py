from rest_framework import serializers, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from apps.authentication.models import UserRole
from apps.authentication.permissions import IsSameOrganizationTenant
from .models import MedicineItem, EquipmentItem, MedicineTransaction

class MedicineTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MedicineTransaction
        fields = '__all__'

class MedicineItemSerializer(serializers.ModelSerializer):
    is_low_stock = serializers.BooleanField(read_only=True)
    transactions = MedicineTransactionSerializer(many=True, read_only=True)

    class Meta:
        model = MedicineItem
        fields = '__all__'

class EquipmentItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = EquipmentItem
        fields = '__all__'

class MedicineViewSet(viewsets.ModelViewSet):
    serializer_class = MedicineItemSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = MedicineItem.objects.all()
        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = MedicineItem.objects.none()
        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(organization=user.organization if user.is_authenticated else None)

    @action(detail=True, methods=['post'])
    def issue_stock(self, request, pk=None):
        from django.db import transaction
        with transaction.atomic():
            med = MedicineItem.objects.select_for_update().get(id=pk)
            qty = int(request.data.get('quantity', 1))
            if qty > med.stock_quantity:
                return Response({'error': f'Insufficient stock available. Current stock: {med.stock_quantity}'}, status=400)

            med.stock_quantity -= qty
            med.save()

            MedicineTransaction.objects.create(
                medicine=med,
                transaction_type=MedicineTransaction.TransactionType.ISSUED,
                quantity=qty,
                recorded_by=request.user.username if request.user.is_authenticated else 'Staff',
                notes=request.data.get('notes', 'Issued via API')
            )
            return Response(MedicineItemSerializer(med).data)



class EquipmentViewSet(viewsets.ModelViewSet):
    serializer_class = EquipmentItemSerializer
    permission_classes = [permissions.IsAuthenticated, IsSameOrganizationTenant]

    def get_queryset(self):
        user = self.request.user
        queryset = EquipmentItem.objects.all()
        if user.is_authenticated and user.role != UserRole.SUPER_ADMIN:
            if user.organization_id:
                queryset = queryset.filter(organization_id=user.organization_id)
            else:
                queryset = EquipmentItem.objects.none()
        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        serializer.save(organization=user.organization if user.is_authenticated else None)

    @action(detail=True, methods=['post'])
    def loan_equipment(self, request, pk=None):
        eq = self.get_object()
        if eq.available_count > 0:
            eq.available_count -= 1
            eq.loaned_count += 1
            eq.save()
            return Response(EquipmentItemSerializer(eq).data)
        return Response({'error': 'No available units to loan'}, status=400)

